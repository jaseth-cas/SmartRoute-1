import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para la gestión de unidades escolares, rutas, paradas y telemetría GPS.
class BusService {
  static const String _busColumns =
      'id, codigo, placa, modelo, capacidad, asientos_ocupados, estado, '
      'dueno_id, conductor_id, colegio_asignado, nombre_ruta, velocidad_kmh, '
      'latitud_actual, longitud_actual, is_verified';
  static const String _stopColumns =
      'id, autobus_codigo, codigo, nombre, referencia, orden, distancia_km, '
      'latitud, longitud, is_favorite';

  final SupabaseClient? _injectedClient;
  final Map<String, String> _profileNamesCache = {};

  BusService({SupabaseClient? supabaseClient}) : _injectedClient = supabaseClient;

  SupabaseClient get _supabase => _injectedClient ?? SupabaseConfig.client;

  /// Calcula el tiempo estimado de llegada (ETA en minutos) según distancia y velocidad (RF-17)
  int calculateEtaMinutes({
    required double distanceKm,
    required int speedKmH,
  }) {
    return AppConstants.calculateEtaMinutes(
      distanceKm: distanceKm,
      speedKmH: speedKmH,
    );
  }

  /// Normaliza un código de ruta o autobús (ej: 'R-BUS-01' -> 'BUS-01')
  String normalizeBusCode(String code) {
    final cleaned = code.trim().toUpperCase();
    return cleaned.startsWith('R-') ? cleaned.substring(2) : cleaned;
  }

  /// Extrae la lista única de colegios cubiertos por un autobús según sus estudiantes activos.
  static List<String> extractCoveredSchools(
    Iterable<StudentPassengerMock> students, {
    String? fallbackSchool,
  }) {
    final schools = <String>{};
    for (final s in students) {
      final name = s.schoolName.trim();
      if (name.isNotEmpty) {
        schools.add(name);
      }
    }
    if (schools.isEmpty &&
        fallbackSchool != null &&
        fallbackSchool.trim().isNotEmpty &&
        fallbackSchool.trim().toLowerCase() != 'múltiples colegios') {
      schools.add(fallbackSchool.trim());
    }
    return schools.toList();
  }

  /// Asegura tener los nombres reales de `conductor_id` y `dueno_id` desde `perfiles`.
  Future<void> _ensureProfileNamesLoaded(Iterable<String?> ids) async {
    final missing = ids
        .where((id) => id != null && id.isNotEmpty && !_profileNamesCache.containsKey(id))
        .cast<String>()
        .toSet()
        .toList();

    if (missing.isEmpty) return;

    try {
      final rows = await _supabase
          .from('perfiles')
          .select('id, nombre')
          .inFilter('id', missing)
          .timeout(const Duration(seconds: 3));

      for (final row in (rows as List)) {
        final id = row['id']?.toString();
        final name = row['nombre']?.toString();
        if (id != null && name != null && name.isNotEmpty) {
          _profileNamesCache[id] = name;
        }
      }
    } catch (e) {
      debugPrint('Aviso resolviendo nombres de perfiles: $e');
    }
  }

  /// Enriquece filas crudas de `autobuses` con nombres de conductor y dueño.
  Future<List<BusMock>> _enrichBusesWithProfiles(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final profileIds = <String?>[
      for (final row in rows) ...[
        row['conductor_id']?.toString(),
        row['dueno_id']?.toString(),
      ],
    ];
    await _ensureProfileNamesLoaded(profileIds);

    return rows.map((row) {
      final driverId = row['conductor_id']?.toString();
      final ownerId = row['dueno_id']?.toString();
      final enriched = Map<String, dynamic>.from(row);

      if (driverId != null && _profileNamesCache.containsKey(driverId)) {
        enriched['conductor_nombre'] = _profileNamesCache[driverId];
      }
      if (ownerId != null && _profileNamesCache.containsKey(ownerId)) {
        enriched['dueno_nombre'] = _profileNamesCache[ownerId];
      }

      return BusMock.fromMap(enriched);
    }).toList();
  }

  /// Obtiene todos los autobuses registrados en PostgreSQL
  Future<List<BusMock>> getAllBuses() async {
    try {
      final response = await _supabase
          .from('autobuses')
          .select(_busColumns)
          .order('codigo', ascending: true)
          .timeout(const Duration(seconds: 3));

      final rows = (response as List).cast<Map<String, dynamic>>();
      return await _enrichBusesWithProfiles(rows);
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getAllBuses [${e.code}]: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Error en getAllBuses: $e');
      return [];
    }
  }

  /// Obtiene un autobús por su código único (ej: 'BUS-01')
  Future<BusMock?> getBusByCode(String code) async {
    final busCode = normalizeBusCode(code);
    if (busCode.isEmpty) return null;

    try {
      final response = await _supabase
          .from('autobuses')
          .select(_busColumns)
          .eq('codigo', busCode)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (response == null) return null;
      final list = await _enrichBusesWithProfiles([response]);
      return list.firstOrNull;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getBusByCode [${e.code}]: ${e.message}');
      return null;
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
          .select(_busColumns)
          .eq('dueno_id', ownerId)
          .order('codigo', ascending: true)
          .timeout(const Duration(seconds: 3));

      final rows = (response as List).cast<Map<String, dynamic>>();
      return await _enrichBusesWithProfiles(rows);
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getBusesByOwner [${e.code}]: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Aviso getBusesByOwner (usando fallback local): $e');
      return MockData.buses;
    }
  }

  /// Obtiene el autobús asignado al conductor autenticado (`conductor_id = driverId`)
  Future<BusMock?> getBusByDriver(String driverId) async {
    try {
      if (driverId.trim().isNotEmpty) {
        final response = await _supabase
            .from('autobuses')
            .select(_busColumns)
            .eq('conductor_id', driverId.trim())
            .order('codigo', ascending: true)
            .limit(1)
            .timeout(const Duration(seconds: 3));

        final rows = (response as List).cast<Map<String, dynamic>>();
        if (rows.isNotEmpty) {
          final enriched = await _enrichBusesWithProfiles(rows);
          return enriched.firstOrNull;
        }
        return null;
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getBusByDriver [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error en getBusByDriver: $e');
      return null;
    }
  }

  /// Alias de creación de autobús en PostgreSQL (RF-02)
  Future<BusMock> createBus({
    required String code,
    required String plate,
    required String model,
    required int capacity,
    String schoolName = 'Múltiples colegios',
    String routeName = 'Ruta Escolar Penonomé',
    String? driverId,
    String? ownerId,
  }) {
    return registerBus(
      code: code,
      plate: plate,
      model: model,
      capacity: capacity,
      schoolName: schoolName,
      routeName: routeName,
      driverId: driverId,
      ownerId: ownerId,
    );
  }

  /// Registra un nuevo autobús escolar en PostgreSQL con coordenadas reales en Penonomé
  Future<BusMock> registerBus({
    required String code,
    required String plate,
    required String model,
    required int capacity,
    String schoolName = 'Múltiples colegios',
    String routeName = 'Ruta Escolar Penonomé',
    String? driverId,
    String? ownerId,
  }) async {
    final resolvedOwnerId = (ownerId != null && ownerId.isNotEmpty)
        ? ownerId
        : _supabase.auth.currentUser?.id;

    final normalizedCode = normalizeBusCode(code).replaceAll(RegExp(r'\s+'), '-');
    final offset = 0.0012 * ((capacity % 6) + 1);
    final data = <String, dynamic>{
      'codigo': normalizedCode,
      'placa': plate.trim().toUpperCase(),
      'modelo': model.trim(),
      'capacidad': capacity,
      'asientos_ocupados': 0,
      'estado': 'Disponible',
      'colegio_asignado': schoolName.trim(),
      'nombre_ruta': routeName.trim(),
      'is_verified': true,
      'latitud_actual': AppConstants.penonomeCenter.latitude + offset,
      'longitud_actual': AppConstants.penonomeCenter.longitude - offset,
    };
    if (resolvedOwnerId != null && resolvedOwnerId.isNotEmpty) {
      data['dueno_id'] = resolvedOwnerId;
    }
    if (driverId != null && driverId.isNotEmpty) {
      data['conductor_id'] = driverId;
    }

    final response = await _supabase
        .from('autobuses')
        .insert(data)
        .select()
        .single()
        .timeout(const Duration(seconds: 5));

    final enriched = await _enrichBusesWithProfiles([response]);
    return enriched.first;
  }

  /// Actualiza los datos técnicos y capacidad de un autobús existente (RF-04)
  Future<BusMock?> updateBus({
    required String code,
    required String plate,
    required String model,
    required int capacity,
    String? schoolName,
    String? routeName,
  }) async {
    final cleanedCode = normalizeBusCode(code);
    final cleanedPlate = plate.trim().toUpperCase();
    final cleanedModel = model.trim();

    try {
      final updates = <String, dynamic>{
        'placa': cleanedPlate,
        'modelo': cleanedModel,
        'capacidad': capacity,
        if (schoolName != null && schoolName.trim().isNotEmpty)
          'colegio_asignado': schoolName.trim(),
        if (routeName != null && routeName.trim().isNotEmpty)
          'nombre_ruta': routeName.trim(),
      };

      final response = await _supabase
          .from('autobuses')
          .update(updates)
          .eq('codigo', cleanedCode)
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (response != null) {
        final enriched = await _enrichBusesWithProfiles([response]);
        return enriched.firstOrNull;
      }
    } catch (e) {
      debugPrint('Error actualizando autobús en Supabase: $e');
      rethrow;
    }
    return null;
  }

  /// Asigna un conductor verificado a una unidad escolar en PostgreSQL (RF-03)
  Future<BusMock?> assignDriverToBus({
    required String busCode,
    required String driverName,
    String? driverId,
  }) async {
    final cleanedCode = normalizeBusCode(busCode);
    try {
      if (driverId != null && driverId.isNotEmpty) {
        _profileNamesCache[driverId] = driverName;
        final response = await _supabase
            .from('autobuses')
            .update({'conductor_id': driverId})
            .eq('codigo', cleanedCode)
            .select()
            .maybeSingle()
            .timeout(const Duration(seconds: 4));

        if (response != null) {
          final enriched = await _enrichBusesWithProfiles([response]);
          return enriched.firstOrNull;
        }
      }
      return await getBusByCode(cleanedCode);
    } catch (e) {
      debugPrint('Error asignando conductor en Supabase: $e');
      rethrow;
    }
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
          .eq('codigo', normalizeBusCode(busCode))
          .timeout(const Duration(seconds: 3));
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
          .eq('codigo', normalizeBusCode(busCode))
          .timeout(const Duration(seconds: 3));
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
          .eq('codigo', normalizeBusCode(busCode))
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error actualizando certificación del bus: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Rutas y Paradas reales (derivadas de `autobuses` + `paradas_ruta`)
  // ---------------------------------------------------------------------------

  RouteMock _buildRouteFromBus(
    BusMock bus,
    List<StopMock> busStops, {
    List<String> coveredSchools = const [],
  }) {
    final firstStop = busStops.isNotEmpty ? busStops.first.name : 'Penonomé Centro';
    final totalDist = busStops.isNotEmpty
        ? busStops.map((s) => s.distanceFromStartKm).reduce((a, b) => a > b ? a : b)
        : 3.5;

    final etaMin = bus.status == 'Finalizado'
        ? 0
        : calculateEtaMinutes(
            distanceKm: totalDist > 0 ? totalDist : 3.5,
            speedKmH: bus.currentSpeedKmH > 0 ? bus.currentSpeedKmH : 28,
          );

    final destinationLabel = coveredSchools.isNotEmpty
        ? coveredSchools.join(' • ')
        : (bus.schoolName ?? 'Múltiples colegios');

    return RouteMock(
      id: bus.id,
      code: bus.code,
      name: bus.routeName ?? 'Ruta Escolar ${bus.code}',
      origin: firstStop,
      destination: destinationLabel,
      status: bus.status,
      etaMinutes: etaMin,
      busCode: bus.code,
      direction: RouteDirection.homeToSchool,
      description:
          '${busStops.length} paradas • Conductor: ${bus.driverName} (${bus.plate})',
      isFavorite: busStops.any((s) => s.isFavorite),
    );
  }

  /// Lista todas las rutas activas construidas desde `autobuses` y `paradas_ruta`
  Future<List<RouteMock>> getAllRoutes() async {
    try {
      final results = await Future.wait([
        getAllBuses(),
        getAllStops(),
      ]);
      final buses = results[0] as List<BusMock>;
      final stops = results[1] as List<StopMock>;

      return buses.map((bus) {
        final busStops = stops.where((s) => s.routeCode == bus.code).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        return _buildRouteFromBus(bus, busStops);
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo rutas: $e');
      return [];
    }
  }

  /// Obtiene una ruta específica por código de ruta o autobús
  Future<RouteMock?> getRouteByCode(String code) async {
    final busCode = normalizeBusCode(code);
    if (busCode.isEmpty) return null;
    try {
      final results = await Future.wait([
        getBusByCode(busCode),
        getStopsByBusCode(busCode),
      ]);
      final bus = results[0] as BusMock?;
      if (bus == null) return null;
      final stops = results[1] as List<StopMock>;
      return _buildRouteFromBus(bus, stops);
    } catch (e) {
      debugPrint('Error en getRouteByCode: $e');
      return null;
    }
  }

  /// Obtiene todas las paradas registradas en `paradas_ruta`
  Future<List<StopMock>> getAllStops() async {
    try {
      final response = await _supabase
          .from('paradas_ruta')
          .select(_stopColumns)
          .order('autobus_codigo', ascending: true)
          .order('orden', ascending: true)
          .timeout(const Duration(seconds: 3));

      return (response as List)
          .map((row) => StopMock.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getAllStops [${e.code}]: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Error obteniendo todas las paradas: $e');
      return [];
    }
  }

  /// Obtiene las paradas de un autobús o ruta específicos ordenadas por secuencia
  Future<List<StopMock>> getStopsByBusCode(String busCode) async {
    final cleaned = normalizeBusCode(busCode);
    if (cleaned.isEmpty) return [];

    try {
      final response = await _supabase
          .from('paradas_ruta')
          .select(_stopColumns)
          .eq('autobus_codigo', cleaned)
          .order('orden', ascending: true)
          .timeout(const Duration(seconds: 3));

      return (response as List)
          .map((row) => StopMock.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getStopsByBusCode [${e.code}]: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Error en getStopsByBusCode: $e');
      return [];
    }
  }

  /// Obtiene una parada por su código único
  Future<StopMock?> getStopByCode(String stopCode) async {
    try {
      final response = await _supabase
          .from('paradas_ruta')
          .select(_stopColumns)
          .eq('codigo', stopCode.trim())
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (response == null) return null;
      return StopMock.fromMap(Map<String, dynamic>.from(response));
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getStopByCode [${e.code}]: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error en getStopByCode: $e');
      return null;
    }
  }

  /// Crea una nueva parada dentro de `paradas_ruta` en PostgreSQL
  Future<StopMock> createStop({
    required String busCode,
    required String name,
    String reference = '',
    required int order,
    required double latitude,
    required double longitude,
    double distanceFromStartKm = 1.0,
  }) async {
    final cleanedBus = normalizeBusCode(busCode);
    final code =
        'P-${cleanedBus.replaceAll('-', '')}-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final response = await _supabase
        .from('paradas_ruta')
        .insert({
          'autobus_codigo': cleanedBus,
          'codigo': code,
          'nombre': name.trim(),
          'referencia': reference.trim(),
          'orden': order,
          'distancia_km': distanceFromStartKm,
          'latitud': latitude,
          'longitud': longitude,
          'is_favorite': false,
        })
        .select()
        .single()
        .timeout(const Duration(seconds: 4));

    return StopMock.fromMap(Map<String, dynamic>.from(response));
  }

  /// Alterna el estado favorito de una parada en `paradas_ruta`
  Future<StopMock?> toggleStopFavorite(String stopCode, bool isFavorite) async {
    try {
      final response = await _supabase
          .from('paradas_ruta')
          .update({'is_favorite': isFavorite})
          .eq('codigo', stopCode.trim())
          .select()
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (response == null) return null;
      return StopMock.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error alternando favorito de parada: $e');
      return null;
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
        .asyncMap((rows) => _enrichBusesWithProfiles(rows));
  }

  /// Stream en tiempo real de un autobús específico (Para el mapa de seguimiento del Padre)
  Stream<BusMock?> streamBusByCode(String busCode) {
    final cleaned = normalizeBusCode(busCode);
    return _supabase
        .from('autobuses')
        .stream(primaryKey: ['id'])
        .eq('codigo', cleaned)
        .asyncMap((rows) async {
          if (rows.isEmpty) return null;
          final enriched = await _enrichBusesWithProfiles([rows.first]);
          return enriched.firstOrNull;
        });
  }

  /// DELETE seguro de un autobús por su código único (`codigo`)
  Future<void> deleteBus(String busCode) async {
    final cleaned = normalizeBusCode(busCode);
    if (cleaned.isEmpty) return;
    try {
      await _supabase
          .from('autobuses')
          .delete()
          .eq('codigo', cleaned)
          .timeout(const Duration(seconds: 4));
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en deleteBus($cleaned) [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error en deleteBus($cleaned): $e');
      rethrow;
    }
  }

  /// DELETE seguro de una parada por su código único (`codigo`)
  Future<void> deleteStop(String stopCode) async {
    final cleaned = stopCode.trim();
    if (cleaned.isEmpty) return;
    try {
      await _supabase
          .from('paradas_ruta')
          .delete()
          .eq('codigo', cleaned)
          .timeout(const Duration(seconds: 4));
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en deleteStop($cleaned) [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error en deleteStop($cleaned): $e');
      rethrow;
    }
  }
}
