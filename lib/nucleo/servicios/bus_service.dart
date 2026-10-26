import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
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
          .order('codigo', ascending: true)
          .timeout(SupabaseConfig.defaultTimeout);

      final list = (response as List).map((row) => BusMock.fromMap(row)).toList();
      if (list.isNotEmpty) return list;
      return MockData.buses;
    } catch (e) {
      debugPrint('Aviso getAllBuses (usando fallback local): $e');
      return MockData.buses;
    }
  }

  /// Obtiene un autobús por su código único (ej: 'BUS-01')
  Future<BusMock?> getBusByCode(String code) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('codigo', code)
          .maybeSingle()
          .timeout(SupabaseConfig.defaultTimeout);

      if (response == null) return MockData.getBusByCode(code);
      return BusMock.fromMap(response);
    } catch (e) {
      debugPrint('Aviso getBusByCode (usando fallback local): $e');
      return MockData.getBusByCode(code);
    }
  }

  /// Obtiene la lista de autobuses que pertenecen a un Dueño de Flota (Transportista)
  Future<List<BusMock>> getBusesByOwner(String ownerId) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('dueno_id', ownerId)
          .order('codigo', ascending: true)
          .timeout(SupabaseConfig.defaultTimeout);

      final list = (response as List).map((row) => BusMock.fromMap(row)).toList();
      return list.isNotEmpty ? list : MockData.buses;
    } catch (e) {
      debugPrint('Aviso getBusesByOwner (usando fallback local): $e');
      return MockData.buses;
    }
  }

  /// Obtiene el autobús asignado al conductor autenticado
  Future<BusMock?> getBusByDriver(String driverId) async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select()
          .eq('conductor_id', driverId)
          .maybeSingle()
          .timeout(SupabaseConfig.defaultTimeout);

      if (response == null) {
        // Fallback al primer autobús si aún no se ha asignado explícitamente
        final all = await getAllBuses();
        return all.isNotEmpty ? all.first : MockData.buses.first;
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

    final data = <String, dynamic>{
      'codigo': code.trim().toUpperCase(),
      'placa': plate.trim().toUpperCase(),
      'modelo': model.trim(),
      'capacidad': capacity,
      'asientos_ocupados': 0,
      'estado': 'Disponible',
      'colegio_asignado': schoolName,
      'nombre_ruta': routeName,
      'is_verified': true,
      'latitud_actual': 9.9340 + (0.0012 * ((capacity % 6) + 1)),
      'longitud_actual': -84.0780 - (0.0012 * ((capacity % 6) + 1)),
    };
    if (currentUserId != null) {
      data['dueno_id'] = currentUserId;
    }

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

  /// Actualiza la certificación del Sello de Confianza (Trust & Safety) del autobús
  Future<void> updateBusVerification({
    required String busCode,
    required bool isVerified,
  }) async {
    try {
      await _supabase
          .from('autobuses')
          .update({'is_verified': isVerified})
          .eq('codigo', busCode);
    } catch (e) {
      debugPrint('Error actualizando certificación del bus: $e');
      rethrow;
    }
  }

  /// Stream en tiempo real de todos los autobuses (Para el mapa del Dueño de Flota)
  Stream<List<BusMock>> streamAllBuses() {
    if (SupabaseConfig.hasCheckedReachability && !SupabaseConfig.isReachable) {
      return Stream.value(MockData.buses);
    }
    return _supabase
        .from('autobuses')
        .stream(primaryKey: ['id'])
        .order('codigo', ascending: true)
        .handleError((e) {
          debugPrint('Aviso stream all buses: $e');
        })
        .map((rows) => rows.isNotEmpty ? rows.map((row) => BusMock.fromMap(row)).toList() : MockData.buses);
  }

  /// Stream en tiempo real de un autobús específico (Para el mapa de seguimiento del Padre)
  Stream<BusMock?> streamBusByCode(String busCode) {
    if (SupabaseConfig.hasCheckedReachability && !SupabaseConfig.isReachable) {
      return Stream.value(MockData.getBusByCode(busCode));
    }
    return _supabase
        .from('autobuses')
        .stream(primaryKey: ['id'])
        .eq('codigo', busCode)
        .handleError((e) {
          debugPrint('Aviso stream bus by code: $e');
        })
        .map((rows) => rows.isNotEmpty ? BusMock.fromMap(rows.first) : MockData.getBusByCode(busCode));
  }
}
