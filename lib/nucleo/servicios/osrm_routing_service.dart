import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Resultado de la optimización de secuencia de paradas con el algoritmo de Dijkstra.
class DijkstraOptimizationResult {
  final List<int> orderedIndices;
  final List<double> legDistancesMeters;
  final double finalLegToDestinationMeters;
  final double totalDistanceMeters;

  const DijkstraOptimizationResult({
    required this.orderedIndices,
    required this.legDistancesMeters,
    required this.finalLegToDestinationMeters,
    required this.totalDistanceMeters,
  });
}

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

  /// Ejecuta el algoritmo de Dijkstra sobre el grafo ponderado G(V, E) formado por:
  /// - V = {origin} U {stopPoints} U {destination}
  /// - w(u, v) = distancia geodésica en metros entre u y v
  ///
  /// En cada iteración calcula las distancias mínimas `d(v) = min(d(v), d(u) + w(u, v))`
  /// desde el nodo actual y selecciona la siguiente parada activa no visitada de menor costo.
  static DijkstraOptimizationResult optimizeStopsWithDijkstra({
    required LatLng origin,
    required List<LatLng> stopPoints,
    required LatLng destination,
  }) {
    if (stopPoints.isEmpty) {
      final directMeters = calculateDistanceMeters(origin, destination);
      return DijkstraOptimizationResult(
        orderedIndices: const [],
        legDistancesMeters: const [],
        finalLegToDestinationMeters: directMeters,
        totalDistanceMeters: directMeters,
      );
    }

    // Construir matriz de adyacencia completa del grafo G(V, E)
    // Índice 0 = origin, 1..n = stopPoints, n+1 = destination
    final n = stopPoints.length;
    final nodes = <LatLng>[origin, ...stopPoints, destination];
    final totalNodes = nodes.length;
    final adj = List.generate(
      totalNodes,
      (i) => List<double>.generate(
        totalNodes,
        (j) => i == j ? 0.0 : calculateDistanceMeters(nodes[i], nodes[j]),
      ),
    );

    final visitedStops = List<bool>.filled(n, false);
    final orderedIndices = <int>[];
    final legDistances = <double>[];
    var currentNode = 0; // Inicia en origin
    var totalDistance = 0.0;

    for (int step = 0; step < n; step++) {
      // Relajación de Dijkstra desde currentNode sobre los nodos no visitados
      final dist = List<double>.filled(totalNodes, double.infinity);
      final settled = List<bool>.filled(totalNodes, false);
      dist[currentNode] = 0.0;

      for (int count = 0; count < totalNodes; count++) {
        int u = -1;
        double minDist = double.infinity;
        for (int v = 0; v < totalNodes; v++) {
          if (!settled[v] && dist[v] < minDist) {
            minDist = dist[v];
            u = v;
          }
        }
        if (u == -1 || minDist == double.infinity) break;
        settled[u] = true;

        for (int v = 0; v < totalNodes; v++) {
          if (!settled[v]) {
            final candidate = dist[u] + adj[u][v];
            if (candidate < dist[v]) {
              dist[v] = candidate;
            }
          }
        }
      }

      // Seleccionar la parada activa (1..n) no visitada con menor costo d(v)
      int bestStopIdx = -1;
      double bestCost = double.infinity;
      for (int s = 0; s < n; s++) {
        if (!visitedStops[s]) {
          final cost = dist[s + 1];
          if (cost < bestCost) {
            bestCost = cost;
            bestStopIdx = s;
          }
        }
      }

      if (bestStopIdx == -1) break;
      visitedStops[bestStopIdx] = true;
      orderedIndices.add(bestStopIdx);
      legDistances.add(bestCost);
      totalDistance += bestCost;
      currentNode = bestStopIdx + 1;
    }

    final finalLeg = adj[currentNode][totalNodes - 1];
    totalDistance += finalLeg;

    return DijkstraOptimizationResult(
      orderedIndices: orderedIndices,
      legDistancesMeters: legDistances,
      finalLegToDestinationMeters: finalLeg,
      totalDistanceMeters: totalDistance,
    );
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
