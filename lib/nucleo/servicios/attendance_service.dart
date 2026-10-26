import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para el control y sincronización de asistencia diaria, ausencias y abordaje biométrico.
class AttendanceService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  String get _todayDate => DateTime.now().toIso8601String().split('T')[0];

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Registra el abordaje del estudiante en el autobús (Biometría Facial AI o Contingencia Manual)
  Future<void> checkInPassenger({
    required int studentId,
    String method = 'Biometría Facial AI',
    String jornada = 'manana',
  }) async {
    final timeStr = _formatCurrentTime();

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
    } catch (e) {
      debugPrint('Error en checkInPassenger: $e');
      rethrow;
    }
  }

  /// Marca que el estudiante ha sido entregado en el colegio o destino final
  Future<void> checkOutPassenger({
    required int studentId,
    String jornada = 'manana',
  }) async {
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
    if (SupabaseConfig.hasCheckedReachability && !SupabaseConfig.isReachable) {
      return const Stream.empty();
    }
    return _supabase
        .from('asistencia_diaria')
        .stream(primaryKey: ['id'])
        .eq('fecha', _todayDate)
        .handleError((e) {
          debugPrint('Aviso stream asistencia: $e');
        });
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
          .eq('fecha', _todayDate)
          .timeout(SupabaseConfig.defaultTimeout);

      final map = <int, Map<String, dynamic>>{};
      for (final row in (response as List)) {
        final id = row['estudiante_id'] is int
            ? row['estudiante_id']
            : int.tryParse(row['estudiante_id'].toString()) ?? 0;
        map[id] = row as Map<String, dynamic>;
      }
      return map;
    } catch (e) {
      debugPrint('Aviso getTodayAttendanceForStudents (usando fallback local): $e');
      return {};
    }
  }
}
