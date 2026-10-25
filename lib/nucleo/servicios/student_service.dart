import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para la gestión de estudiantes matriculados, asignación de cupos y resumen financiero.
class StudentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Obtiene los estudiantes asignados a un autobús con su asistencia del día combinada
  Future<List<StudentPassengerMock>> getStudentsByBus(String busCode) async {
    try {
      // 1. Consultar lista de estudiantes matriculados en la unidad
      final studentsResponse = await _supabase
          .from('estudiantes_pasajeros')
          .select()
          .eq('autobus_codigo', busCode)
          .order('orden', ascending: true);

      final studentsList = studentsResponse as List;
      if (studentsList.isEmpty) return [];

      // 2. Consultar asistencias del día actual para estos estudiantes
      final studentIds = studentsList.map((s) => s['id']).toList();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final attendanceResponse = await _supabase
          .from('asistencia_diaria')
          .select()
          .filter('estudiante_id', 'in', studentIds)
          .eq('fecha', todayStr);

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in (attendanceResponse as List)) {
        final id = att['estudiante_id'] is int
            ? att['estudiante_id']
            : int.tryParse(att['estudiante_id'].toString()) ?? 0;
        attendanceMap[id] = att as Map<String, dynamic>;
      }

      // 3. Mapear cada estudiante con su asistencia del día
      return studentsList.map((row) {
        final id = row['id'] is int
            ? row['id']
            : int.tryParse(row['id'].toString()) ?? 0;
        final att = attendanceMap[id];
        return StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
      }).toList();
    } catch (e) {
      debugPrint('Error en getStudentsByBus: $e');
      return [];
    }
  }

  /// Obtiene el o los estudiantes a cargo del padre autenticado
  Future<List<StudentPassengerMock>> getStudentsByParent(String parentId) async {
    try {
      final response = await _supabase
          .from('estudiantes_pasajeros')
          .select()
          .eq('padre_id', parentId);

      final studentsList = response as List;
      if (studentsList.isEmpty) return [];

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final studentIds = studentsList.map((s) => s['id']).toList();

      final attendanceResponse = await _supabase
          .from('asistencia_diaria')
          .select()
          .filter('estudiante_id', 'in', studentIds)
          .eq('fecha', todayStr);

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in (attendanceResponse as List)) {
        final id = att['estudiante_id'] is int
            ? att['estudiante_id']
            : int.tryParse(att['estudiante_id'].toString()) ?? 0;
        attendanceMap[id] = att as Map<String, dynamic>;
      }

      return studentsList.map((row) {
        final id = row['id'] is int
            ? row['id']
            : int.tryParse(row['id'].toString()) ?? 0;
        final att = attendanceMap[id];
        return StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
      }).toList();
    } catch (e) {
      debugPrint('Error en getStudentsByParent: $e');
      return [];
    }
  }

  /// Retorna el estudiante principal del padre (o el primero de prueba si no hay sesión)
  Future<StudentPassengerMock?> getPrimaryStudent(String? parentId) async {
    if (parentId != null && parentId.isNotEmpty) {
      final list = await getStudentsByParent(parentId);
      if (list.isNotEmpty) return list.first;
    }

    // Fallback: Primer estudiante del sistema
    final fallbackList = await getStudentsByBus('BUS-01');
    return fallbackList.isNotEmpty ? fallbackList.first : null;
  }

  /// Obtiene todos los estudiantes registrados para el control del transportista
  Future<List<StudentPassengerMock>> getAllStudents() async {
    try {
      final response = await _supabase
          .from('estudiantes_pasajeros')
          .select()
          .order('orden', ascending: true);

      final list = (response as List).map((row) {
        return StudentPassengerMock.fromMap(row as Map<String, dynamic>);
      }).toList();

      if (list.isNotEmpty) return list;
      return MockData.passengers;
    } catch (e) {
      debugPrint('Error en getAllStudents: $e');
      return MockData.passengers;
    }
  }

  /// Calcula el resumen financiero y métricas de aforo para el transportista
  Future<FleetFinancialSummary> getFleetFinancialSummary([String? ownerId]) async {
    try {
      // Consultar autobuses
      var busesQuery = _supabase.from('autobuses').select('capacidad, asientos_ocupados');
      if (ownerId != null) {
        busesQuery = busesQuery.eq('dueno_id', ownerId);
      }
      final busesData = await busesQuery;

      int totalSeats = 0;
      int occupiedSeats = 0;
      for (final b in (busesData as List)) {
        totalSeats += (b['capacidad'] as num?)?.toInt() ?? 0;
        occupiedSeats += (b['asientos_ocupados'] as num?)?.toInt() ?? 0;
      }

      // Consultar estudiantes y estados de pago
      final studentsData = await _supabase
          .from('estudiantes_pasajeros')
          .select('cuota_mensual, estado_pago');

      double totalRevenue = 0.0;
      double pendingRevenue = 0.0;
      int pendingPaymentsCount = 0;
      final int totalStudents = (studentsData as List).length;

      for (final s in studentsData) {
        final fee = double.tryParse(s['cuota_mensual']?.toString() ?? '65.0') ?? 65.0;
        final status = s['estado_pago']?.toString() ?? 'Al día';

        if (status == 'Al día') {
          totalRevenue += fee;
        } else {
          pendingRevenue += fee;
          pendingPaymentsCount++;
        }
      }

      return FleetFinancialSummary(
        totalSeats: totalSeats > 0 ? totalSeats : 36,
        occupiedSeats: occupiedSeats > 0 ? occupiedSeats : totalStudents,
        totalRevenue: totalRevenue,
        pendingRevenue: pendingRevenue,
        pendingPaymentsCount: pendingPaymentsCount,
        totalStudents: totalStudents,
      );
    } catch (e) {
      debugPrint('Error calculando FleetFinancialSummary: $e');
      return const FleetFinancialSummary(
        totalSeats: 36,
        occupiedSeats: 32,
        totalRevenue: 2080.0,
        pendingRevenue: 65.0,
        pendingPaymentsCount: 1,
        totalStudents: 5,
      );
    }
  }

  /// Actualiza los datos de contacto o dirección de un estudiante
  Future<void> updateStudentProfile({
    required int studentId,
    String? name,
    String? pickupAddress,
    String? parentPhone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['nombre'] = name.trim();
      if (pickupAddress != null) updates['direccion_recogida'] = pickupAddress.trim();
      if (parentPhone != null) updates['padre_telefono'] = parentPhone.trim();

      if (updates.isNotEmpty) {
        await _supabase
            .from('estudiantes_pasajeros')
            .update(updates)
            .eq('id', studentId);
      }
    } catch (e) {
      debugPrint('Error en updateStudentProfile: $e');
    }
  }
}
