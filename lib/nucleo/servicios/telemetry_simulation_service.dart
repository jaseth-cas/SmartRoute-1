import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/route_optimizer_service.dart';

/// Modo de fuente de telemetría del autobús:
/// - [simulated]: avanza sobre los vértices reales de la polilínea OSRM + Dijkstra.
/// - [realGps]: preparado para recibir lecturas físicas de `geolocator` del chofer.
enum TelemetryMode {
  simulated,
  realGps,
}

/// Instantánea inmutable del estado de telemetría en vivo de un autobús.
class TelemetrySnapshot {
  final LatLng position;
  final double speedKmH;
  final double distanceTraveledMeters;
  final double progress;
  final String nextStopLabel;
  final bool isPlaying;
  final double speedMultiplier;
  final TelemetryMode mode;

  const TelemetrySnapshot({
    required this.position,
    required this.speedKmH,
    required this.distanceTraveledMeters,
    required this.progress,
    required this.nextStopLabel,
    required this.isPlaying,
    required this.speedMultiplier,
    required this.mode,
  });
}

/// Controlador desacoplado de telemetría y simulación realista sobre rutas Dijkstra + OSRM.
/// Publica actualizaciones throttled a Supabase (`autobuses`) y notifica a la UI.
class BusTelemetryController extends ChangeNotifier {
  final BusService? busService;
  final Duration tickInterval;
  final Duration syncInterval;

  OptimizedBusRoute? _route;
  TelemetryMode _mode = TelemetryMode.simulated;
  bool _isPlaying = false;
  double _speedMultiplier = 1.0;

  int _vertexIndex = 0;
  double _segmentDistanceMeters = 0.0;
  double _distanceTraveledMeters = 0.0;
  LatLng _currentPosition = AppConstants.penonomeCenter;
  double _currentSpeedKmH = 0.0;
  String _nextStopLabel = 'Calculando siguiente parada...';

  Timer? _tickTimer;
  DateTime _lastSupabaseSync = DateTime.fromMillisecondsSinceEpoch(0);
  int _tickCount = 0;
  bool _isDisposed = false;

  BusTelemetryController({
    this.busService,
    this.tickInterval = const Duration(milliseconds: 400),
    this.syncInterval = const Duration(milliseconds: 2500),
  });

  OptimizedBusRoute? get route => _route;
  TelemetryMode get mode => _mode;
  bool get isPlaying => _isPlaying;
  double get speedMultiplier => _speedMultiplier;
  LatLng get currentPosition => _currentPosition;
  double get currentSpeedKmH => _currentSpeedKmH;
  double get distanceTraveledMeters => _distanceTraveledMeters;
  String get nextStopLabel => _nextStopLabel;
  int get currentVertexIndex => _vertexIndex;

  double get progress {
    final total = _route?.totalDistanceMeters ?? 0.0;
    if (total <= 0) return 0.0;
    return (_distanceTraveledMeters / total).clamp(0.0, 1.0);
  }

  TelemetrySnapshot get snapshot => TelemetrySnapshot(
        position: _currentPosition,
        speedKmH: _currentSpeedKmH,
        distanceTraveledMeters: _distanceTraveledMeters,
        progress: progress,
        nextStopLabel: _nextStopLabel,
        isPlaying: _isPlaying,
        speedMultiplier: _speedMultiplier,
        mode: _mode,
      );

  /// Actualiza la ruta activa de Dijkstra + OSRM.
  /// Si [preserveProgress] es true y el autobús ya iba en ruta, reancla al vértice más cercano
  /// para incorporar nuevos estudiantes sin reiniciar el recorrido.
  void updateRoute(OptimizedBusRoute newRoute, {bool preserveProgress = true}) {
    final hadRoute = _route != null && _distanceTraveledMeters > 0;
    _route = newRoute;

    if (newRoute.polylinePoints.isEmpty) {
      _currentPosition = newRoute.origin;
      _vertexIndex = 0;
      _segmentDistanceMeters = 0.0;
      _distanceTraveledMeters = 0.0;
      _nextStopLabel = 'Sin paradas activas';
      _safeNotify();
      return;
    }

    if (preserveProgress && hadRoute) {
      int closestIdx = 0;
      double bestDist = double.infinity;
      for (int i = 0; i < newRoute.polylinePoints.length; i++) {
        final d = OsrmRoutingService.calculateDistanceMeters(
          _currentPosition,
          newRoute.polylinePoints[i],
        );
        if (d < bestDist) {
          bestDist = d;
          closestIdx = i;
        }
      }
      _vertexIndex = closestIdx.clamp(0, newRoute.polylinePoints.length - 1);
      _segmentDistanceMeters = 0.0;
      _currentPosition = newRoute.polylinePoints[_vertexIndex];
      _distanceTraveledMeters = _computeDistanceUpToVertex(
        newRoute.polylinePoints,
        _vertexIndex,
      );
    } else {
      _vertexIndex = 0;
      _segmentDistanceMeters = 0.0;
      _distanceTraveledMeters = 0.0;
      _currentPosition = newRoute.polylinePoints.first;
    }

    _updateNextStopLabel();
    _safeNotify();
  }

  double _computeDistanceUpToVertex(List<LatLng> pts, int idx) {
    double sum = 0.0;
    for (int i = 1; i <= idx && i < pts.length; i++) {
      sum += OsrmRoutingService.calculateDistanceMeters(pts[i - 1], pts[i]);
    }
    return sum;
  }

  /// Inicia o reanuda la simulación sobre la polilínea OSRM.
  void start() {
    if (_mode != TelemetryMode.simulated) return;
    if (_isPlaying) return;
    _isPlaying = true;
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(tickInterval, (_) => stepSimulation());
    _safeNotify();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _currentSpeedKmH = 0.0;
    _tickTimer?.cancel();
    _tickTimer = null;
    _syncToSupabase(force: true);
    _safeNotify();
  }

  void resume() => start();

  void reset() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _isPlaying = false;
    _vertexIndex = 0;
    _segmentDistanceMeters = 0.0;
    _distanceTraveledMeters = 0.0;
    _currentSpeedKmH = 0.0;
    final pts = _route?.polylinePoints;
    if (pts != null && pts.isNotEmpty) {
      _currentPosition = pts.first;
    }
    _updateNextStopLabel();
    _syncToSupabase(force: true);
    _safeNotify();
  }

  void setSpeedMultiplier(double multiplier) {
    _speedMultiplier = multiplier.clamp(0.5, 4.0);
    _safeNotify();
  }

  void setMode(TelemetryMode newMode) {
    if (_mode == newMode) return;
    _mode = newMode;
    if (newMode == TelemetryMode.realGps) {
      _tickTimer?.cancel();
      _tickTimer = null;
      _isPlaying = false;
    }
    _safeNotify();
  }

  /// Contrato para inyectar lecturas reales de GPS físico del conductor cuando [mode] == [TelemetryMode.realGps].
  void pushRealGpsSample(LatLng position, {double? speedMetersPerSecond}) {
    _currentPosition = position;
    _currentSpeedKmH = speedMetersPerSecond != null
        ? (speedMetersPerSecond * 3.6).clamp(0.0, 120.0)
        : 0.0;
    _updateNextStopLabel();
    _syncToSupabase();
    _safeNotify();
  }

  /// Avanza un paso discreto en la simulación (público también para pruebas deterministas).
  void stepSimulation() {
    final activeRoute = _route;
    if (activeRoute == null || activeRoute.polylinePoints.length < 2) return;

    final pts = activeRoute.polylinePoints;
    if (_vertexIndex >= pts.length - 1) {
      _currentPosition = pts.last;
      _currentSpeedKmH = 0.0;
      _isPlaying = false;
      _tickTimer?.cancel();
      _tickTimer = null;
      _nextStopLabel = activeRoute.orderedSchools.isNotEmpty
          ? 'Llegada a ${activeRoute.orderedSchools.last.name}'
          : 'Recorrido completado';
      _syncToSupabase(force: true);
      _safeNotify();
      return;
    }

    _tickCount++;
    // Velocidad urbana realista en Penonomé: 32–44 km/h con variación suave
    final baseKmH = 36.0 + 6.0 * math.sin(_tickCount * 0.35);
    _currentSpeedKmH = baseKmH;
    final metersPerSecond = (baseKmH * 1000.0) / 3600.0;
    double stepMeters =
        metersPerSecond * (tickInterval.inMilliseconds / 1000.0) * _speedMultiplier;

    while (stepMeters > 0 && _vertexIndex < pts.length - 1) {
      final a = pts[_vertexIndex];
      final b = pts[_vertexIndex + 1];
      final segLen = OsrmRoutingService.calculateDistanceMeters(a, b);

      if (segLen <= 0.1) {
        _vertexIndex++;
        _segmentDistanceMeters = 0.0;
        continue;
      }

      final remainingInSeg = segLen - _segmentDistanceMeters;
      if (stepMeters >= remainingInSeg) {
        stepMeters -= remainingInSeg;
        _distanceTraveledMeters += remainingInSeg;
        _vertexIndex++;
        _segmentDistanceMeters = 0.0;
        _currentPosition = pts[_vertexIndex];
      } else {
        _segmentDistanceMeters += stepMeters;
        _distanceTraveledMeters += stepMeters;
        final t = (_segmentDistanceMeters / segLen).clamp(0.0, 1.0);
        _currentPosition = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        stepMeters = 0.0;
      }
    }

    _updateNextStopLabel();
    _syncToSupabase();
    _safeNotify();
  }

  void _updateNextStopLabel() {
    final activeRoute = _route;
    if (activeRoute == null || activeRoute.waypointsMeta.isEmpty) {
      _nextStopLabel = 'Ruta escolar activa';
      return;
    }
    // Buscar el hito más cercano aún pendiente o el último destino
    String bestLabel = activeRoute.waypointsMeta.last.label;
    double bestDist = double.infinity;
    for (final wp in activeRoute.waypointsMeta) {
      final d = OsrmRoutingService.calculateDistanceMeters(_currentPosition, wp.point);
      if (d > 25.0 && d < bestDist) {
        bestDist = d;
        bestLabel = wp.label;
      }
    }
    _nextStopLabel = bestLabel;
  }

  void _syncToSupabase({bool force = false}) {
    final activeBusService = busService;
    final activeRoute = _route;
    if (activeBusService == null || activeRoute == null) return;

    final now = DateTime.now();
    if (!force && now.difference(_lastSupabaseSync) < syncInterval) return;
    _lastSupabaseSync = now;

    unawaited(
      activeBusService.updateBusLocation(
        busCode: activeRoute.busCode,
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        speedKmH: _currentSpeedKmH.round(),
      ),
    );
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tickTimer?.cancel();
    _tickTimer = null;
    super.dispose();
  }
}
