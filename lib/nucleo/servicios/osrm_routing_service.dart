import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Información detallada sobre el punto de acceso vehicular más cercano sobre una calle transitable.
class OsrmNearestStreetInfo {
  final LatLng snappedPoint;
  final String streetName;
  final double distanceMeters;

  const OsrmNearestStreetInfo({
    required this.snappedPoint,
    required this.streetName,
    required this.distanceMeters,
  });
}

/// Servicio de enrutamiento vial y ajuste a calles transitables basado en OSRM (Open Source Routing Machine).
class OsrmRoutingService {
  static const String _baseUrl = 'https://router.project-osrm.org';
  final http.Client _httpClient;
  final Duration timeout;

  OsrmRoutingService({
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 6),
  }) : _httpClient = httpClient ?? http.Client();

  /// Consulta la API de OSRM (`/route/v1/driving/...`) para obtener la polilínea exacta
  /// que sigue la red de calles transitables entre todos los [waypoints].
  ///
  /// Si ocurre un error de red, timeout o menos de 2 puntos, retorna un fallback controlado.
  Future<List<LatLng>> getDrivingRoute(List<LatLng> waypoints) async {
    if (waypoints.isEmpty) return const [];
    if (waypoints.length == 1) return [waypoints.first];

    // OSRM exige el orden {longitud},{latitud} separado por ';'
    final coordsParam = waypoints
        .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
        .join(';');

    final uri = Uri.parse(
      '$_baseUrl/route/v1/driving/$coordsParam?overview=full&geometries=geojson&steps=false',
    );

    try {
      final response = await _httpClient.get(uri).timeout(timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['code'] == 'Ok') {
          final routes = decoded['routes'] as List<dynamic>?;
          if (routes != null && routes.isNotEmpty) {
            final geometry = routes.first['geometry'] as Map<String, dynamic>?;
            final coordinates = geometry?['coordinates'] as List<dynamic>?;
            if (coordinates != null && coordinates.isNotEmpty) {
              return coordinates.map((coord) {
                final pair = coord as List<dynamic>;
                final lon = (pair[0] as num).toDouble();
                final lat = (pair[1] as num).toDouble();
                return LatLng(lat, lon);
              }).toList();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso OSRM getDrivingRoute (usando fallback interpolado): $e');
    }

    // Fallback controlado: interpolación densificada entre waypoints
    return _buildFallbackInterpolatedRoute(waypoints);
  }

  /// Consulta `https://router.project-osrm.org/nearest/v1/driving/{lon},{lat}` para detectar
  /// el punto de acceso vehicular más cercano sobre una calle transitable.
  Future<LatLng?> snapToNearestStreet(LatLng point) async {
    final info = await getNearestStreetInfo(point);
    return info?.snappedPoint;
  }

  /// Obtiene tanto la coordenada ajustada a la calle más cercana como el nombre de la vía y la distancia en metros.
  Future<OsrmNearestStreetInfo?> getNearestStreetInfo(LatLng point) async {
    final coordParam = '${point.longitude.toStringAsFixed(6)},${point.latitude.toStringAsFixed(6)}';
    final uri = Uri.parse('$_baseUrl/nearest/v1/driving/$coordParam?number=1');

    try {
      final response = await _httpClient.get(uri).timeout(timeout);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['code'] == 'Ok') {
          final waypoints = decoded['waypoints'] as List<dynamic>?;
          if (waypoints != null && waypoints.isNotEmpty) {
            final wp = waypoints.first as Map<String, dynamic>;
            final location = wp['location'] as List<dynamic>?;
            if (location != null && location.length >= 2) {
              final snappedLon = (location[0] as num).toDouble();
              final snappedLat = (location[1] as num).toDouble();
              final snappedLatLng = LatLng(snappedLat, snappedLon);
              final rawName = wp['name']?.toString().trim() ?? '';
              final distance = (wp['distance'] as num?)?.toDouble() ??
                  calculateDistanceMeters(point, snappedLatLng);

              return OsrmNearestStreetInfo(
                snappedPoint: snappedLatLng,
                streetName: rawName.isNotEmpty ? rawName : 'Vía Vehicular Transitable',
                distanceMeters: distance,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso OSRM snapToNearestStreet: $e');
    }

    // Fallback controlado cuando no hay conexión externa
    return OsrmNearestStreetInfo(
      snappedPoint: point,
      streetName: 'Acceso Vehicular Directo',
      distanceMeters: 0.0,
    );
  }

  /// Calcula la distancia geodésica aproximada en metros entre dos coordenadas [LatLng].
  static double calculateDistanceMeters(LatLng p1, LatLng p2) {
    final latAvg = (p1.latitude + p2.latitude) / 2.0 * math.pi / 180.0;
    final dy = (p2.latitude - p1.latitude) * 111320.0;
    final dx = (p2.longitude - p1.longitude) * 111320.0 * math.cos(latAvg);
    return math.sqrt(dx * dx + dy * dy);
  }

  List<LatLng> _buildFallbackInterpolatedRoute(List<LatLng> waypoints) {
    final result = <LatLng>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      result.add(start);
      const steps = 4;
      for (int s = 1; s < steps; s++) {
        final t = s / steps;
        result.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * t,
            start.longitude + (end.longitude - start.longitude) * t,
          ),
        );
      }
    }
    result.add(waypoints.last);
    return result;
  }
}
