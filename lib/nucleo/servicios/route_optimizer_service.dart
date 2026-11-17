import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';

/// Metadato de un hito (domicilio de estudiante o colegio destino) sobre la ruta óptima.
class RouteWaypointMeta {
  final String label;
  final LatLng point;
  final bool isSchool;

  const RouteWaypointMeta({
    required this.label,
    required this.point,
    required this.isSchool,
  });
}

/// Resultado completo y compartido de la ruta óptima de Dijkstra + OSRM para un autobús.
class OptimizedBusRoute {
  final String busCode;
  final LatLng origin;
  final List<StudentPassengerMock> orderedActiveStudents;
  final List<({String name, LatLng point})> orderedSchools;
  final List<LatLng> polylinePoints;
  final List<List<LatLng>> segments;
  final List<RouteWaypointMeta> waypointsMeta;
  final double totalDistanceMeters;
  final int estimatedMinutes;

  const OptimizedBusRoute({
    required this.busCode,
    required this.origin,
    required this.orderedActiveStudents,
    required this.orderedSchools,
    required this.polylinePoints,
    required this.segments,
    required this.waypointsMeta,
    required this.totalDistanceMeters,
    required this.estimatedMinutes,
  });
}

/// Servicio compartido que construye la ruta óptima (Dijkstra + OSRM con fallback offline)
/// para un autobús, soportando múltiples colegios destino y recálculo reactivo en vivo.
class RouteOptimizerService {
  final OsrmRoutingService _osrmService;

  RouteOptimizerService({OsrmRoutingService? osrmService})
      : _osrmService = osrmService ?? OsrmRoutingService();

  /// Construye la ruta óptima para [bus] considerando únicamente estudiantes activos
  /// (excluyendo ausentes) y enlazando al final con todos los colegios distintos cubiertos.
  Future<OptimizedBusRoute> buildOptimalRoute({
    required BusMock bus,
    required List<StudentPassengerMock> students,
  }) async {
    final origin = (bus.latitude != null && bus.longitude != null)
        ? LatLng(bus.latitude!, bus.longitude!)
        : AppConstants.penonomeCenter;

    final activeStudents = students
        .where((s) =>
            s.busCode == bus.code &&
            s.status != PassengerStatus.absent)
        .toList();

    final coveredSchools = BusService.extractCoveredSchools(
      activeStudents,
      fallbackSchool: bus.schoolName,
    );
    final rawSchools = coveredSchools.isNotEmpty
        ? coveredSchools
            .map((name) => (name: name, point: AppConstants.resolveSchoolPoint(name)))
            .toList()
        : [
            (
              name: bus.schoolName ?? 'Colegio Ángel María Herrera',
              point: AppConstants.resolveSchoolPoint(bus.schoolName),
            ),
          ];

    // 1. Ordenar paradas de estudiantes activos con Dijkstra desde la posición del bus
    final orderedStudents = <StudentPassengerMock>[];
    if (activeStudents.isNotEmpty) {
      final studentPoints = activeStudents
          .map((s) => (s.pickupLatitude != null && s.pickupLongitude != null)
              ? LatLng(s.pickupLatitude!, s.pickupLongitude!)
              : AppConstants.penonomeCenter)
          .toList();

      final studentDijkstra = OsrmRoutingService.optimizeStopsWithDijkstra(
        origin: origin,
        stopPoints: studentPoints,
        destination: rawSchools.first.point,
      );
      for (final idx in studentDijkstra.orderedIndices) {
        orderedStudents.add(activeStudents[idx]);
      }
    }

    // 2. Ordenar los distintos colegios destino con Dijkstra desde la última parada
    final lastPickupPoint = orderedStudents.isNotEmpty
        ? LatLng(
            orderedStudents.last.pickupLatitude ?? AppConstants.penonomeCenter.latitude,
            orderedStudents.last.pickupLongitude ?? AppConstants.penonomeCenter.longitude,
          )
        : origin;

    final orderedSchools = <({String name, LatLng point})>[];
    if (rawSchools.length <= 1) {
      orderedSchools.addAll(rawSchools);
    } else {
      final schoolDijkstra = OsrmRoutingService.optimizeStopsWithDijkstra(
        origin: lastPickupPoint,
        stopPoints: rawSchools.map((e) => e.point).toList(),
        destination: rawSchools.last.point,
      );
      for (final idx in schoolDijkstra.orderedIndices) {
        orderedSchools.add(rawSchools[idx]);
      }
    }

    // 3. Construir hitos ordenados y tramos viales reales vía OSRM (con fallback offline)
    final waypointsMeta = <RouteWaypointMeta>[
      for (final s in orderedStudents)
        RouteWaypointMeta(
          label: 'Casa: ${s.name}',
          point: LatLng(
            s.pickupLatitude ?? AppConstants.penonomeCenter.latitude,
            s.pickupLongitude ?? AppConstants.penonomeCenter.longitude,
          ),
          isSchool: false,
        ),
      for (final sch in orderedSchools)
        RouteWaypointMeta(
          label: sch.name,
          point: sch.point,
          isSchool: true,
        ),
    ];

    final segments = <List<LatLng>>[];
    final fullPolyline = <LatLng>[];
    double totalMeters = 0.0;
    LatLng prev = origin;

    for (final wp in waypointsMeta) {
      final seg = await _osrmService.getDrivingRoute([prev, wp.point]);
      final safeSeg = seg.length >= 2 ? seg : [prev, wp.point];
      segments.add(safeSeg);
      for (int i = 0; i < safeSeg.length; i++) {
        if (fullPolyline.isEmpty || i > 0) {
          fullPolyline.add(safeSeg[i]);
        }
        if (i > 0) {
          totalMeters += OsrmRoutingService.calculateDistanceMeters(
            safeSeg[i - 1],
            safeSeg[i],
          );
        }
      }
      prev = wp.point;
    }

    final etaMinutes = AppConstants.calculateEtaMinutes(
      distanceKm: totalMeters / 1000.0,
      speedKmH: bus.currentSpeedKmH > 0 ? bus.currentSpeedKmH : 34,
    );

    return OptimizedBusRoute(
      busCode: bus.code,
      origin: origin,
      orderedActiveStudents: orderedStudents,
      orderedSchools: orderedSchools,
      polylinePoints: fullPolyline,
      segments: segments,
      waypointsMeta: waypointsMeta,
      totalDistanceMeters: totalMeters,
      estimatedMinutes: etaMinutes,
    );
  }

  /// Suscribe un callback reactivo a cambios en tiempo real de `estudiantes_pasajeros`
  /// (Realtime + stream local) y `asistencia_diaria` para recalcular rutas sin reiniciar la app.
  static Future<void> Function() subscribeToRouteTriggers({
    required StudentService studentService,
    AttendanceService? attendanceService,
    required String channelPrefix,
    required VoidCallback onRouteDataChanged,
  }) {
    final locationSub = StudentService.locationUpdatesStream.listen((_) {
      onRouteDataChanged();
    });

    StreamSubscription<List<Map<String, dynamic>>>? attendanceSub;
    if (attendanceService != null) {
      try {
        attendanceSub = attendanceService.streamTodayAttendance().listen(
          (_) => onRouteDataChanged(),
          onError: (e) => debugPrint('Aviso stream asistencia en ruta: $e'),
        );
      } catch (e) {
        debugPrint('Aviso iniciando stream asistencia en ruta: $e');
      }
    }

    final RealtimeChannel? studentsChannel = studentService.subscribeToStudentChanges(
      channelName: '${channelPrefix}_${DateTime.now().millisecondsSinceEpoch}',
      onChanged: onRouteDataChanged,
    );

    return () async {
      await locationSub.cancel();
      await attendanceSub?.cancel();
      await studentService.unsubscribeChannel(studentsChannel);
    };
  }
}
