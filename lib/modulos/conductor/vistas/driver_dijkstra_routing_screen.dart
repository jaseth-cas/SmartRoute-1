import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_card_sorting_screen.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/route_optimizer_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/telemetry_simulation_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Pantalla 3 del nuevo flujo del conductor:
/// Ventana completa del mapa con cálculo real de camino mínimo con Dijkstra sobre coordenadas
/// reales de estudiantes activos, trazado de calles vía OSRM (con fallback offline)
/// y consolidación de la ruta óptima final hacia el panel principal del conductor.
class DriverDijkstraRoutingScreen extends StatefulWidget {
  final List<StudentStopCardItem>? orderedStudents;
  final OsrmRoutingService? osrmService;

  const DriverDijkstraRoutingScreen({
    super.key,
    this.orderedStudents,
    this.osrmService,
  });

  @override
  State<DriverDijkstraRoutingScreen> createState() => _DriverDijkstraRoutingScreenState();
}

class _DriverDijkstraRoutingScreenState extends State<DriverDijkstraRoutingScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final OsrmRoutingService _osrmRoutingService;
  late final RouteOptimizerService _routeOptimizer;
  BusTelemetryController? _telemetryController;
  Future<void> Function()? _unsubscribeRouteTriggers;

  // Lista ordenada de estudiantes activos (sin ausentes) tras aplicar Dijkstra
  late List<StudentStopCardItem> _students;
  BusMock? _activeBus;

  // Coordenadas clave en Penonomé
  LatLng _busOrigin = AppConstants.penonomeCenter;
  LatLng _schoolDest = AppConstants.defaultSchoolPoint;
  String _schoolName = 'Colegio Ángel María Herrera';
  List<({String name, LatLng point})> _schoolDestinations = const [];

  // Fases de la animación de Dijkstra
  int _currentStep = 0;
  String _algorithmStatusText = 'Inicializando Grafo G(V, E) en Penonomé...';
  String _dijkstraFormulaText = 'd(v) = min(d(v), d(u) + w(u,v))';
  double _calculationProgress = 0.0;
  bool _isRouteOptimized = false;
  bool _hasNavigated = false;
  bool _userInteractedWithSim = false;
  bool _routeRecalculatedBanner = false;
  double _totalRouteDistanceMeters = 0.0;

  // Segmentos de ruta calculados y fijados por Dijkstra + OSRM
  final List<List<LatLng>> _confirmedSegments = [];
  // Segmentos explorados/candidatos que parpadean durante el escaneo
  List<LatLng> _currentScanningSegment = [];

  Timer? _stepTimer;
  Timer? _autoFinishTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _osrmRoutingService = widget.osrmService ?? OsrmRoutingService();
    _routeOptimizer = RouteOptimizerService(osrmService: _osrmRoutingService);
    _students = (widget.orderedStudents ?? const <StudentStopCardItem>[])
        .where((s) => !s.isAbsent)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTelemetryAndSubscriptions();
      _initStudentsAndSimulate();
    });
  }

  void _initTelemetryAndSubscriptions() {
    if (!mounted) return;
    BusService? busService;
    try {
      busService = context.read<BusService>();
    } catch (_) {}
    _telemetryController = BusTelemetryController(busService: busService)
      ..addListener(_onTelemetryTick);

    try {
      final studentService = context.read<StudentService>();
      AttendanceService? attendanceService;
      try {
        attendanceService = context.read<AttendanceService>();
      } catch (_) {}
      _unsubscribeRouteTriggers = RouteOptimizerService.subscribeToRouteTriggers(
        studentService: studentService,
        attendanceService: attendanceService,
        channelPrefix: 'driver_dijkstra_route',
        onRouteDataChanged: _recalculateRouteLive,
      );
    } catch (e) {
      debugPrint('Aviso suscribiendo recálculo en vivo Dijkstra: $e');
    }
  }

  void _onTelemetryTick() {
    if (mounted) setState(() {});
  }

  Future<void> _recalculateRouteLive() async {
    if (!mounted || _activeBus == null) return;
    try {
      final studentService = context.read<StudentService>();
      final freshStudents = await studentService.getStudentsByBus(_activeBus!.code);
      final optimized = await _routeOptimizer.buildOptimalRoute(
        bus: _activeBus!,
        students: freshStudents,
      );
      if (!mounted) return;

      final updatedCards = optimized.orderedActiveStudents.map((s) {
        final pos = (s.pickupLatitude != null && s.pickupLongitude != null)
            ? LatLng(s.pickupLatitude!, s.pickupLongitude!)
            : AppConstants.penonomeCenter;
        final dist = OsrmRoutingService.calculateDistanceMeters(_busOrigin, pos);
        final eta = AppConstants.calculateEtaMinutes(
          distanceKm: dist / 1000.0,
          speedKmH: 28,
        );
        return StudentStopCardItem(
          id: s.id,
          name: s.name,
          pickupAddress: s.pickupAddress,
          schoolName: s.schoolName,
          grade: '${s.busCode} • Parada #${s.order}',
          position: pos,
          distanceMeters: dist,
          estimatedTime: '~$eta min',
        );
      }).toList();

      setState(() {
        _students = updatedCards;
        _schoolDestinations = optimized.orderedSchools;
        _totalRouteDistanceMeters = optimized.totalDistanceMeters;
        _confirmedSegments
          ..clear()
          ..addAll(optimized.segments);
        _routeRecalculatedBanner = true;
      });
      _telemetryController?.updateRoute(optimized, preserveProgress: true);
    } catch (e) {
      debugPrint('Aviso recalculando ruta en vivo: $e');
    }
  }

  Future<void> _initStudentsAndSimulate() async {
    try {
      final session = context.read<SessionManager>().currentSession;
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();
      final bus = (session != null && session.userId.isNotEmpty)
          ? await busService.getBusByDriver(session.userId)
          : null;
      _activeBus = bus;

      if (bus?.latitude != null && bus?.longitude != null) {
        _busOrigin = LatLng(bus!.latitude!, bus.longitude!);
      }

      if (_students.isEmpty) {
        final list = bus != null
            ? await studentService.getStudentsByBus(bus.code)
            : await studentService.getAllStudents();
        _students = list
            .where((s) => s.status != PassengerStatus.absent)
            .map((s) {
              final pos = (s.pickupLatitude != null && s.pickupLongitude != null)
                  ? LatLng(s.pickupLatitude!, s.pickupLongitude!)
                  : AppConstants.penonomeCenter;
              final distFromOrigin =
                  OsrmRoutingService.calculateDistanceMeters(_busOrigin, pos);
              final etaMin = AppConstants.calculateEtaMinutes(
                distanceKm: distFromOrigin / 1000.0,
                speedKmH: 28,
              );
              return StudentStopCardItem(
                id: s.id,
                name: s.name,
                pickupAddress: s.pickupAddress,
                schoolName: s.schoolName,
                grade: '${s.busCode} • Parada #${s.order}',
                position: pos,
                distanceMeters: distFromOrigin,
                estimatedTime: '~$etaMin min',
              );
            })
            .toList();
      }

      final coveredSchools = BusService.extractCoveredSchools(
        _students.map(
          (s) => StudentPassengerMock(
            id: s.id,
            name: s.name,
            parentName: '',
            parentPhone: '',
            schoolName: s.schoolName,
            pickupAddress: s.pickupAddress,
            busCode: bus?.code ?? 'BUS-01',
            routeCode: bus?.code ?? 'BUS-01',
            order: 1,
            status: PassengerStatus.waiting,
          ),
        ),
        fallbackSchool: bus?.schoolName,
      );

      if (coveredSchools.isNotEmpty) {
        _schoolDestinations = coveredSchools
            .map((name) => (name: name, point: AppConstants.resolveSchoolPoint(name)))
            .toList();
        _schoolName = coveredSchools.length == 1
            ? coveredSchools.first
            : '${coveredSchools.length} colegios destino';
        _schoolDest = _schoolDestinations.first.point;
      } else {
        _schoolDestinations = [
          (name: _schoolName, point: AppConstants.defaultSchoolPoint),
        ];
      }

      // Ejecutar optimización real de Dijkstra sobre el grafo G(V, E)
      if (_students.isNotEmpty) {
        final result = OsrmRoutingService.optimizeStopsWithDijkstra(
          origin: _busOrigin,
          stopPoints: _students.map((s) => s.position).toList(),
          destination: _schoolDest,
        );
        _totalRouteDistanceMeters = result.totalDistanceMeters;
        double cumulativeMeters = 0.0;
        final reordered = <StudentStopCardItem>[];
        for (int i = 0; i < result.orderedIndices.length; i++) {
          final original = _students[result.orderedIndices[i]];
          final legMeters = result.legDistancesMeters[i];
          cumulativeMeters += legMeters;
          final etaMin = AppConstants.calculateEtaMinutes(
            distanceKm: cumulativeMeters / 1000.0,
            speedKmH: 28,
          );
          reordered.add(
            StudentStopCardItem(
              id: original.id,
              name: original.name,
              pickupAddress: original.pickupAddress,
              schoolName: original.schoolName,
              grade: original.grade,
              position: original.position,
              distanceMeters: legMeters,
              estimatedTime: '~$etaMin min',
              photoAsset: original.photoAsset,
              isAbsent: false,
            ),
          );
        }
        _students = reordered;
      }
    } catch (e) {
      debugPrint('Aviso inicializando Dijkstra routing: $e');
    }

    if (!mounted) return;
    await _startDijkstraSimulation();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _autoFinishTimer?.cancel();
    _telemetryController?.removeListener(_onTelemetryTick);
    _telemetryController?.dispose();
    unawaited(_unsubscribeRouteTriggers?.call() ?? Future<void>.value());
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startDijkstraSimulation() async {
    if (_students.isEmpty) {
      setState(() {
        _isRouteOptimized = true;
        _calculationProgress = 1.0;
        _algorithmStatusText = 'Ruta lista hacia $_schoolName';
      });
      _autoFinishTimer = Timer(const Duration(milliseconds: 1500), _goToDriverHomeScreen);
      return;
    }

    // Precalcular tramos reales sobre calles con OSRM (y fallback offline automático)
    final osrmSegments = <List<LatLng>>[];
    for (int i = 0; i < _students.length; i++) {
      final prevPos = i == 0 ? _busOrigin : _students[i - 1].position;
      final seg = await _osrmRoutingService.getDrivingRoute([prevPos, _students[i].position]);
      osrmSegments.add(seg.length >= 2 ? seg : [prevPos, _students[i].position]);
    }
    final destPoints = _schoolDestinations.isNotEmpty
        ? _schoolDestinations.map((d) => d.point).toList()
        : [_schoolDest];
    final finalSeg = await _osrmRoutingService.getDrivingRoute([
      _students.last.position,
      ...destPoints,
    ]);
    osrmSegments.add(
      finalSeg.length >= 2 ? finalSeg : [_students.last.position, ...destPoints],
    );

    if (!mounted) return;

    int step = 0;
    final totalSteps = _students.length + 2;

    _stepTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      step++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentStep = step;
        _calculationProgress = (step / totalSteps).clamp(0.0, 1.0);

        if (step <= _students.length) {
          final idx = step - 1;
          final student = _students[idx];
          final segPoints = osrmSegments[idx];
          _algorithmStatusText =
              'Dijkstra: Parada $step (${student.name}) • ${student.formattedDistance}';
          _dijkstraFormulaText =
              'd(v) = min(d(v), d(u) + w(u,v)) • ETA ${student.estimatedTime}';
          _currentScanningSegment = segPoints;
          _confirmedSegments.add(segPoints);
        } else if (step == _students.length + 1) {
          final segPoints = osrmSegments.last;
          _algorithmStatusText = 'Dijkstra: Enlazando con $_schoolName...';
          _dijkstraFormulaText = 'Tramo final sobre red vial OSRM';
          _currentScanningSegment = segPoints;
          _confirmedSegments.add(segPoints);
        } else {
          timer.cancel();
          _isRouteOptimized = true;
          _calculationProgress = 1.0;
          _currentScanningSegment = [];
          final totalKm = (_totalRouteDistanceMeters / 1000.0).toStringAsFixed(2);
          _algorithmStatusText = '¡Ruta Óptima Calculada ($totalKm km)!';
          _dijkstraFormulaText =
              '${_students.length} paradas activas optimizadas con Dijkstra + OSRM';

          // Cargar ruta consolidada en el motor de telemetría
          final fullPts = <LatLng>[];
          for (final seg in osrmSegments) {
            for (int k = 0; k < seg.length; k++) {
              if (fullPts.isEmpty || k > 0) fullPts.add(seg[k]);
            }
          }
          final waypointsMeta = <RouteWaypointMeta>[
            for (final s in _students)
              RouteWaypointMeta(label: 'Casa: ${s.name}', point: s.position, isSchool: false),
            for (final d in (_schoolDestinations.isNotEmpty
                ? _schoolDestinations
                : [(name: _schoolName, point: _schoolDest)]))
              RouteWaypointMeta(label: d.name, point: d.point, isSchool: true),
          ];
          _telemetryController?.updateRoute(
            OptimizedBusRoute(
              busCode: _activeBus?.code ?? 'BUS-01',
              origin: _busOrigin,
              orderedActiveStudents: const [],
              orderedSchools: _schoolDestinations,
              polylinePoints: fullPts,
              segments: List<List<LatLng>>.from(osrmSegments),
              waypointsMeta: waypointsMeta,
              totalDistanceMeters: _totalRouteDistanceMeters,
              estimatedMinutes: AppConstants.calculateEtaMinutes(
                distanceKm: _totalRouteDistanceMeters / 1000.0,
                speedKmH: 34,
              ),
            ),
            preserveProgress: false,
          );

          _autoFinishTimer = Timer(const Duration(milliseconds: 2200), () {
            if (!_userInteractedWithSim) {
              _goToDriverHomeScreen();
            }
          });
        }
      });
    });
  }

  void _goToDriverHomeScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _stepTimer?.cancel();
    _autoFinishTimer?.cancel();
    if (mounted) {
      context.go('/driver_home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Polilínea acumulada consolidada
    final consolidatedPoints = <LatLng>[];
    for (final seg in _confirmedSegments) {
      consolidatedPoints.addAll(seg);
    }

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: Stack(
        children: [
          // 1. Mapa Interactivo Completo
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(8.5218, -80.3525),
              initialZoom: 15.0,
              minZoom: 12.0,
              maxZoom: 18.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartroute.smartroute_flutter',
              ),

              // Capa de Polilíneas de Dijkstra
              PolylineLayer(
                polylines: [
                  // 1. Segmentos de escaneo/exploración Dijkstra (Amarillo/Ámbar parpadeante)
                  if (_currentScanningSegment.isNotEmpty)
                    Polyline(
                      points: _currentScanningSegment,
                      color: SmartColors.smartYellow.withValues(alpha: 0.65),
                      strokeWidth: 8.0,
                    ),

                  // 2. Halo resplandeciente de ruta consolidada
                  if (consolidatedPoints.isNotEmpty)
                    Polyline(
                      points: consolidatedPoints,
                      color: _isRouteOptimized
                          ? SmartColors.vibrantCyan.withValues(alpha: 0.45)
                          : SmartColors.deepBlue.withValues(alpha: 0.35),
                      strokeWidth: 10.0,
                    ),

                  // 3. Línea central de camino mínimo confirmado
                  if (consolidatedPoints.isNotEmpty)
                    Polyline(
                      points: consolidatedPoints,
                      color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                      strokeWidth: 5.5,
                    ),
                ],
              ),

              // Marcadores del Grafo
              MarkerLayer(
                markers: [
                  // Origen: Bus del Conductor
                  Marker(
                    point: _busOrigin,
                    width: 140,
                    height: 52,
                    child: _buildNodeMarker(
                      title: 'INICIO DE RUTA',
                      subtitle: 'Posición actual',
                      icon: Icons.directions_bus_filled_rounded,
                      color: SmartColors.deepBlue,
                    ),
                  ),

                  // Nodos de los Estudiantes del Card Sorting
                  ..._students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final isConfirmed = _currentStep > index;

                    return Marker(
                      point: student.position,
                      width: 150,
                      height: 54,
                      child: _buildNodeMarker(
                        title: '0${index + 1}. ${student.name.split(' ').first}',
                        subtitle: student.formattedDistance,
                        icon: Icons.person_pin_circle_rounded,
                        color: isConfirmed ? SmartColors.vibrantCyan : SmartColors.smartGray,
                        isHighlighted: _currentStep == index + 1,
                      ),
                    );
                  }),

                  // Marcador en vivo del autobús simulado / GPS real
                  if (_telemetryController != null)
                    Marker(
                      point: _telemetryController!.currentPosition,
                      width: 56,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlack,
                          shape: BoxShape.circle,
                          border: Border.all(color: SmartColors.vibrantCyan, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: SmartColors.vibrantCyan.withValues(alpha: 0.45),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: SmartColors.vibrantCyan,
                          size: 26,
                        ),
                      ),
                    ),
                  // Destinos: Todos los colegios cubiertos por los estudiantes activos
                  ...(_schoolDestinations.isNotEmpty
                          ? _schoolDestinations
                          : [(name: _schoolName, point: _schoolDest)])
                      .map(
                    (dest) => Marker(
                      point: dest.point,
                      width: 155,
                      height: 52,
                      child: _buildNodeMarker(
                        title: dest.name.toUpperCase(),
                        subtitle: 'Destino Escolar',
                        icon: Icons.school_rounded,
                        color: SmartColors.smartGreen,
                        isHighlighted: _isRouteOptimized,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. HUD Superior de Dijkstra: Monitor Algorítmico y Telemetría
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: SmartColors.deepBlack.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SmartColors.deepBlack.withValues(alpha: 0.4),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fila Superior: Badge Algoritmo y Botón Omitir (sin overflow en pantallas de 360px)
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _isRouteOptimized
                                      ? SmartColors.vibrantCyan.withValues(alpha: 0.2)
                                      : SmartColors.smartYellow.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _isRouteOptimized
                                            ? 'DIJKSTRA // ÓPTIMO'
                                            : 'DIJKSTRA // RUTA MÍNIMA',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón Omitir e ir directamente al mapa principal
                          GestureDetector(
                            onTap: _goToDriverHomeScreen,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartColors.neuInset.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'OMITIR',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.skip_next_rounded, size: 14, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Título de la Fase y Fórmula
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _algorithmStatusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dijkstraFormulaText,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: SmartColors.vibrantCyan,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SmartColors.neuInset.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(_calculationProgress * 100).toInt()}%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _isRouteOptimized ? SmartColors.vibrantCyan : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Barra de Progreso del Algoritmo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _calculationProgress,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                          ),
                        ),
                      ),
                      if (_isRouteOptimized && _telemetryController != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_telemetryController!.currentSpeedKmH.toStringAsFixed(0)} km/h • Próx: ${_telemetryController!.nextStopLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                _userInteractedWithSim = true;
                                _autoFinishTimer?.cancel();
                                if (_telemetryController!.isPlaying) {
                                  _telemetryController!.pause();
                                } else {
                                  _telemetryController!.start();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: SmartColors.vibrantCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _telemetryController!.isPlaying ? 'PAUSAR' : 'SIMULAR',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.vibrantCyan,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                _userInteractedWithSim = true;
                                _autoFinishTimer?.cancel();
                                final next = _telemetryController!.speedMultiplier == 1.0 ? 2.0 : 1.0;
                                _telemetryController!.setSpeedMultiplier(next);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_telemetryController!.speedMultiplier.toInt()}x',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                _userInteractedWithSim = true;
                                _autoFinishTimer?.cancel();
                                final nextMode =
                                    _telemetryController!.mode == TelemetryMode.simulated
                                        ? TelemetryMode.realGps
                                        : TelemetryMode.simulated;
                                _telemetryController!.setMode(nextMode);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _telemetryController!.mode == TelemetryMode.simulated
                                      ? 'SIM'
                                      : 'GPS',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.smartYellow,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_routeRecalculatedBanner) ...[
                        const SizedBox(height: 6),
                        Text(
                          '↻ Ruta recalculada automáticamente con cambios en tiempo real',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.smartGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Tarjeta Inferior de Consolidación y Transición
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: NeumorphicBox(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      // Icono de Estado
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isRouteOptimized
                              ? SmartColors.smartGreen.withValues(alpha: 0.15)
                              : SmartColors.deepBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isRouteOptimized ? Icons.check_circle_rounded : Icons.hub_rounded,
                            color: _isRouteOptimized ? SmartColors.smartGreen : SmartColors.deepBlue,
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Detalles de Ruta Mínima Consolidada
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRouteOptimized ? 'RUTA ESCOLAR LISTA PARA NAVEGACIÓN' : 'CONSTRUYENDO GRAFO DE RECOGIDA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: _isRouteOptimized ? SmartColors.smartGreen : SmartColors.smartGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRouteOptimized
                                  ? '4.8 km • 14 min • 4 estudiantes en secuencia óptima'
                                  : 'Evaluando distancias euclidianas y pesos viales...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botón para ingresar al panel principal
                      ElevatedButton(
                        onPressed: _goToDriverHomeScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SmartColors.deepBlack,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.neuBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isRouteOptimized ? 'Iniciar Navegación' : 'Ir al Panel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: SmartColors.vibrantCyan, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeMarker({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SmartColors.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? SmartColors.vibrantCyan : color,
          width: isHighlighted ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isHighlighted ? SmartColors.vibrantCyan : color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: SmartColors.vibrantCyan,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

