import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para el control y sincronización de asistencia diaria, ausencias y abordaje biométrico.
class AttendanceService {
  final SupabaseClient? _injectedClient;

  AttendanceService({SupabaseClient? supabaseClient}) : _injectedClient = supabaseClient;

  SupabaseClient get _supabase => _injectedClient ?? SupabaseConfig.client;

  String get _todayDate => DateTime.now().toIso8601String().split('T')[0];

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Filtra el manifiesto del día devolviendo únicamente las paradas activas (excluyendo ausentes - RF-11)
  List<StudentPassengerMock> getActiveManifest(List<StudentPassengerMock> passengers) {
    final active = passengers.where((p) => p.status != PassengerStatus.absent).toList();
    active.sort((a, b) => a.order.compareTo(b.order));
    return active;
  }

  /// Calcula el ahorro estimado de tiempo y recorrido por paradas omitidas debido a inasistencias (RF-11)
  Map<String, num> calculateRouteSavings(List<StudentPassengerMock> passengers) {
    final absentCount = passengers.where((p) => p.status == PassengerStatus.absent).length;
    return {
      'omittedStops': absentCount,
      'savedMinutes': absentCount * 4,
      'savedKilometers': double.parse((absentCount * 1.2).toStringAsFixed(1)),
    };
  }

  /// Registra el abordaje del estudiante en el autobús (Biometría Facial AI o Contingencia Manual)
  /// y envía notificación push inmediata de Prueba de Vida al padre (RF-09, RF-10, RF-15).
  Future<void> checkInPassenger({
    required int studentId,
    String method = 'Biometría Facial AI',
    String jornada = 'manana',
  }) async {
    final timeStr = _formatCurrentTime();
    MockData.checkInPassenger(studentId, method: method);

    final student = MockData.passengers.where((p) => p.id == studentId).firstOrNull;
    final studentName = student?.name ?? 'Estudiante #$studentId';
    final busCode = student?.busCode ?? 'BUS-01';

    try {
      await _supabase.from('asistencia_diaria').upsert(
        {
          'estudiante_id': studentId,
          'fecha': _todayDate,
          'jornada': jornada,
          'estado': 'onboard',
          'hora_abordaje': timeStr,
          'metodo_abordaje': method,
        },
        onConflict: 'estudiante_id,fecha,jornada',
      );

      // RF-15: Disparar notificación push inmediata de confirmación de abordaje
      await _supabase.from('notificaciones').insert({
        'autobus_codigo': busCode,
        'titulo': 'Abordaje Confirmado ($method)',
        'mensaje': '$studentName abordó el autobús $busCode de forma segura a las $timeStr.',
        'tipo': 'system',
        'leida': false,
      });
    } catch (e) {
      debugPrint('Error en checkInPassenger: $e');
      rethrow;
    }
  }

  /// Marca que el estudiante ha sido entregado en el colegio o destino final
  /// y notifica automáticamente al padre de familia (RF-15).
  Future<void> checkOutPassenger({
    required int studentId,
    String jornada = 'manana',
  }) async {
    final timeStr = _formatCurrentTime();
    MockData.checkOutPassenger(studentId);

    final student = MockData.passengers.where((p) => p.id == studentId).firstOrNull;
    final studentName = student?.name ?? 'Estudiante #$studentId';
    final busCode = student?.busCode ?? 'BUS-01';
    final schoolName = student?.schoolName ?? 'el colegio';

    try {
      await _supabase.from('asistencia_diaria').upsert(
        {
          'estudiante_id': studentId,
          'fecha': _todayDate,
          'jornada': jornada,
          'estado': 'delivered',
        },
        onConflict: 'estudiante_id,fecha,jornada',
      );

      // RF-15: Disparar notificación push de llegada segura al colegio
      await _supabase.from('notificaciones').insert({
        'autobus_codigo': busCode,
        'titulo': 'Llegada Segura al Colegio',
        'mensaje': '$studentName ingresó a $schoolName a las $timeStr.',
        'tipo': 'info',
        'leida': false,
      });
    } catch (e) {
      debugPrint('Error en checkOutPassenger: $e');
      rethrow;
    }
  }

  /// Declara o cancela la inasistencia del estudiante reportada por el padre de familia
  Future<void> reportAbsence({
    required int studentId,
    required bool isAbsent,
    String jornada = 'manana',
  }) async {
    final newState = isAbsent ? 'absent' : 'waiting';

    try {
      await _supabase.from('asistencia_diaria').upsert(
        {
          'estudiante_id': studentId,
          'fecha': _todayDate,
          'jornada': jornada,
          'estado': newState,
          if (isAbsent) 'hora_abordaje': null,
          if (isAbsent) 'metodo_abordaje': null,
        },
        onConflict: 'estudiante_id,fecha,jornada',
      );
    } catch (e) {
      debugPrint('Error en reportAbsence: $e');
      rethrow;
    }
  }

  /// Stream en tiempo real de todos los eventos de asistencia del día (WebSockets)
  Stream<List<Map<String, dynamic>>> streamTodayAttendance() {
    return _supabase
        .from('asistencia_diaria')
        .stream(primaryKey: ['id'])
        .eq('fecha', _todayDate);
  }

  /// Obtiene los registros de asistencia del día actual para una lista de estudiantes
  Future<Map<int, Map<String, dynamic>>> getTodayAttendanceForStudents(
    List<int> studentIds,
  ) async {
    if (studentIds.isEmpty) return {};

    try {
      final response = await _supabase
          .from('asistencia_diaria')
          .select()
          .filter('estudiante_id', 'in', studentIds)
          .eq('fecha', _todayDate);

      final map = <int, Map<String, dynamic>>{};
      for (final row in (response as List)) {
        final id = row['estudiante_id'] is int
            ? row['estudiante_id']
            : int.tryParse(row['estudiante_id'].toString()) ?? 0;
        map[id] = row as Map<String, dynamic>;
      }
      return map;
    } catch (e) {
      debugPrint('Error en getTodayAttendanceForStudents: $e');
      return {};
    }
  }
}
