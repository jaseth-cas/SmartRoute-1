import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para la gestión de unidades escolares, cupos y telemetría GPS.
class BusService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  /// Obtiene todos los autobuses registrados en la base de datos
  Future<List<BusMock>> getAllBuses() async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .order('codigo', ascending: true);

      return (response as List).map((row) => BusMock.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Error en getAllBuses: $e');
      return [];
    }
  }

  /// Obtiene un autobús por su código único (ej: 'BUS-01')
  Future<BusMock?> getBusByCode(String code) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('codigo', code)
          .maybeSingle();

      if (response == null) return null;
      return BusMock.fromMap(response);
    } catch (e) {
      debugPrint('Error en getBusByCode: $e');
      return null;
    }
  }

  /// Obtiene la lista de autobuses que pertenecen a un Dueño de Flota (Transportista)
  Future<List<BusMock>> getBusesByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('dueno_id', ownerId)
          .order('codigo', ascending: true);

      return (response as List).map((row) => BusMock.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Error en getBusesByOwner: $e');
      return [];
    }
  }

  /// Obtiene el autobús asignado al conductor autenticado
  Future<BusMock?> getBusByDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('conductor_id', driverId)
          .maybeSingle();

      if (response == null) {
        // Fallback al primer autobús si aún no se ha asignado explícitamente
        final all = await getAllBuses();
        return all.isNotEmpty ? all.first : null;
      }
      return BusMock.fromMap(response);
    } catch (e) {
      debugPrint('Error en getBusByDriver: $e');
      return null;
    }
  }

  /// Registra un nuevo autobús escolar en PostgreSQL
  Future<BusMock> registerBus({
    required String code,
    required String plate,
    required String model,
    required int capacity,
    String schoolName = 'Colegio San José',
    String routeName = 'Ruta Escolar Norte',
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    final data = {
      'codigo': code.trim().toUpperCase(),
      'placa': plate.trim().toUpperCase(),
      'modelo': model.trim(),
      'capacidad': capacity,
      'asientos_ocupados': 0,
      'estado': 'Disponible',
      'colegio_asignado': schoolName,
      'nombre_ruta': routeName,
      'dueno_id': currentUserId,
      'is_verified': true,
    };

    final response = await _supabase
        .from('autobuses')
        .insert(data)
        .select()
        .single();

    return BusMock.fromMap(response);
  }

  /// Actualiza la telemetría GPS del vehículo en vivo (Emitido por el conductor)
  Future<void> updateBusLocation({
    required String busCode,
    required double latitude,
    required double longitude,
    int? speedKmH,
  }) async {
    try {
      final updates = <String, dynamic>{
        'latitud_actual': latitude,
        'longitud_actual': longitude,
      };
      if (speedKmH != null) {
        updates['velocidad_kmh'] = speedKmH;
      }

      await _supabase
          .from('autobuses')
          .update(updates)
          .eq('codigo', busCode);
    } catch (e) {
      debugPrint('Error actualizando ubicación GPS: $e');
    }
  }

  /// Actualiza el estado operativo de la unidad ('En recorrido', 'Disponible', 'Detenido')
  Future<void> updateBusStatus({
    required String busCode,
    required String status,
  }) async {
    try {
      await _supabase
          .from('autobuses')
          .update({'estado': status})
          .eq('codigo', busCode);
    } catch (e) {
      debugPrint('Error actualizando estado del bus: $e');
    }
  }

  /// Stream en tiempo real de todos los autobuses (Para el mapa del Dueño de Flota)
  Stream<List<BusMock>> streamAllBuses() {
    return _supabase
        .from('autobuses')
        .stream(primaryKey: ['id'])
        .order('codigo', ascending: true)
        .map((rows) => rows.map((row) => BusMock.fromMap(row)).toList());
  }

  /// Stream en tiempo real de un autobús específico (Para el mapa de seguimiento del Padre)
  Stream<BusMock?> streamBusByCode(String busCode) {
    return _supabase
        .from('autobuses')
        .stream(primaryKey: ['id'])
        .eq('codigo', busCode)
        .map((rows) => rows.isNotEmpty ? BusMock.fromMap(rows.first) : null);
  }
}
