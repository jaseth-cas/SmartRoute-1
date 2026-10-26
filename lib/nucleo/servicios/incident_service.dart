import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para el reporte de incidentes en ruta y gestión de notificaciones escolares en vivo.
class IncidentService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Registra un incidente vial o mecánico reportado por el conductor y difunde la alerta
  Future<void> reportIncident({
    required String busCode,
    required String title,
    required String description,
    required String incidentType,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      // 1. Guardar en la tabla de incidentes de ruta
      await _supabase.from('incidentes_ruta').insert({
        'autobus_codigo': busCode,
        'conductor_id': currentUserId,
        'tipo': incidentType,
        'titulo': title.trim(),
        'descripcion': description.trim(),
      });

      // 2. Disparar notificación push para los padres y transportistas asociados
      await _supabase.from('notificaciones').insert({
        'autobus_codigo': busCode,
        'titulo': title.trim(),
        'mensaje': '[$incidentType] ${description.trim()}',
        'tipo': (incidentType == 'Mecánico' || incidentType == 'Accidente') ? 'alert' : 'info',
        'leida': false,
      });
    } catch (e) {
      debugPrint('Error en reportIncident: $e');
      rethrow;
    }
  }

  /// Consulta la lista de notificaciones escolares recientes
  Future<List<NotificationMock>> getNotifications({String? busCode}) async {
    try {
      var query = _supabase.from('notificaciones').select();
      if (busCode != null && busCode.isNotEmpty) {
        query = query.eq('autobus_codigo', busCode);
      }

      final response = await query.order('created_at', ascending: false).limit(50);

      return (response as List).map((row) {
        final id = row['id'] is int ? row['id'] : int.tryParse(row['id']?.toString() ?? '0') ?? 0;
        final createdAt = row['created_at'] != null
            ? DateTime.tryParse(row['created_at'].toString())?.toLocal()
            : null;

        String timeStr = 'Reciente';
        if (createdAt != null) {
          final diff = DateTime.now().difference(createdAt);
          if (diff.inMinutes < 1) {
            timeStr = 'Justo ahora';
          } else if (diff.inMinutes < 60) {
            timeStr = 'Hace ${diff.inMinutes} min';
          } else if (diff.inHours < 24) {
            timeStr = 'Hace ${diff.inHours} h';
          } else {
            timeStr = 'Hace ${diff.inDays} d';
          }
        }

        return NotificationMock(
          id: id,
          title: row['titulo'] ?? 'Aviso Escolar',
          message: row['mensaje'] ?? '',
          time: timeStr,
          read: row['leida'] ?? false,
          type: row['tipo'] ?? 'info',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error en getNotifications: $e');
      return [];
    }
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(int notificationId) async {
    try {
      await _supabase
          .from('notificaciones')
          .update({'leida': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error en markAsRead: $e');
    }
  }

  /// Stream en tiempo real de notificaciones (WebSockets)
  Stream<List<NotificationMock>> streamNotifications({String? busCode}) {
    return _supabase
        .from('notificaciones')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map((row) {
            final id = row['id'] is int ? row['id'] : int.tryParse(row['id']?.toString() ?? '0') ?? 0;
            return NotificationMock(
              id: id,
              title: row['titulo'] ?? 'Aviso Escolar',
              message: row['mensaje'] ?? '',
              time: 'En vivo',
              read: row['leida'] ?? false,
              type: row['tipo'] ?? 'info',
            );
          }).toList();
        });
  }
}
