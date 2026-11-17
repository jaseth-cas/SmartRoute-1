import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para la gestión de estudiantes matriculados, asignación de cupos,
/// flujo GET -> PUT, coordenadas exactas de recogida (GPS / manual) y resumen financiero.
class StudentService {
  static const String _studentColumns =
      'id, nombre, padre_nombre, padre_telefono, padre_id, colegio, '
      'direccion_recogida, autobus_codigo, orden, cuota_mensual, estado_pago, '
      'latitud_recogida, longitud_recogida';
  static const String _attendanceColumns =
      'estudiante_id, fecha, jornada, estado, hora_abordaje, metodo_abordaje';

  final SupabaseClient? _injectedClient;

  /// Stream global en memoria para notificar al instante a todos los módulos
  /// (Padre, Conductor y Transportista) cuando cambia la ubicación o perfil de un estudiante.
  static final StreamController<StudentPassengerMock> _locationUpdatesController =
      StreamController<StudentPassengerMock>.broadcast();

  static Stream<StudentPassengerMock> get locationUpdatesStream =>
      _locationUpdatesController.stream;

  /// Caché de prioridad de cambios realizados en la sesión activa para evitar que
  /// lecturas asíncronas antiguas pisen una ubicación recién guardada.
  static final Map<int, StudentPassengerMock> _localSessionOverrides = {};

  StudentService({SupabaseClient? supabaseClient}) : _injectedClient = supabaseClient;

  SupabaseClient get _supabase => _injectedClient ?? SupabaseConfig.client;

  /// Suscripción Realtime (WebSocket Postgres Changes) sobre `public.estudiantes_pasajeros`.
  /// Permite que los mapas del Conductor y del Dueño refresquen pines y rutas al instante
  /// cuando un padre guarda o modifica su ubicación de recogida desde cualquier dispositivo.
  RealtimeChannel? subscribeToStudentChanges({
    required String channelName,
    required VoidCallback onChanged,
  }) {
    try {
      final channel = _supabase.channel(channelName)
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'estudiantes_pasajeros',
          callback: (_) => onChanged(),
        )
        ..subscribe();
      return channel;
    } catch (e) {
      debugPrint('Aviso suscribiendo Realtime de estudiantes ($channelName): $e');
      return null;
    }
  }

  /// Cancela limpiamente un canal Realtime de `estudiantes_pasajeros`.
  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {
    if (channel == null) return;
    try {
      await _supabase.removeChannel(channel);
    } catch (e) {
      debugPrint('Aviso cerrando canal Realtime: $e');
    }
  }

  /// Verifica si un autobús aún dispone de asientos físicos libres antes de matricular (RF-05)
  bool canEnrollStudent(BusMock bus) {
    return bus.hasAvailableSeats;
  }

  /// Sincroniza el contador `asientos_ocupados` de un autobús en PostgreSQL
  /// contando directamente los registros en `estudiantes_pasajeros`.
  Future<void> _syncBusSeatCount(String busCode) async {
    final cleaned = busCode.trim().toUpperCase();
    if (cleaned.isEmpty || cleaned == 'SIN ASIGNAR') return;
    try {
      final rows = await _supabase
          .from('estudiantes_pasajeros')
          .select('id')
          .eq('autobus_codigo', cleaned)
          .timeout(const Duration(seconds: 3));

      final count = (rows as List).length;
      await _supabase
          .from('autobuses')
          .update({'asientos_ocupados': count})
          .eq('codigo', cleaned)
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Aviso sincronizando asientos_ocupados ($cleaned): $e');
    }
  }

  /// Obtiene los datos del perfil de un tutor desde `public.perfiles`
  Future<Map<String, dynamic>?> getParentProfileById(String parentId) async {
    if (parentId.trim().isEmpty) return null;
    try {
      return await _supabase
          .from('perfiles')
          .select('id, nombre, email, telefono, rol')
          .eq('id', parentId.trim())
          .maybeSingle()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Error en getParentProfileById: $e');
      return null;
    }
  }

  /// GET unificado de un estudiante por su ID, incluyendo asistencia del día y parada asociada.
  Future<StudentPassengerMock?> getStudentById(int studentId) async {
    if (studentId <= 0) return null;
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select(_studentColumns)
            .eq('id', studentId)
            .maybeSingle()
            .timeout(const Duration(seconds: 3)),
        _supabase
            .from('asistencia_diaria')
            .select(_attendanceColumns)
            .eq('estudiante_id', studentId)
            .eq('fecha', todayStr)
            .maybeSingle()
            .timeout(const Duration(seconds: 3)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final row = results[0] as Map<String, dynamic>?;
      if (row == null) return _localSessionOverrides[studentId];

      final att = results[1] as Map<String, dynamic>?;
      final stopsCoordsMap =
          results[2] as Map<int, ({double lat, double lng, String? reference})>;

      var student = StudentPassengerMock.fromMap(row, att);
      student = _enrichWithCoordinates(student, stopsCoordsMap);
      _localSessionOverrides[studentId] = student;
      return student;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en getStudentById($studentId) [${e.code}]: ${e.message}');
      return _localSessionOverrides[studentId];
    } catch (e) {
      debugPrint('Error en getStudentById($studentId): $e');
      return _localSessionOverrides[studentId];
    }
  }

  /// Matricula un nuevo estudiante en un autobús validando el control de aforo / sobrecupo (RF-05)
  Future<StudentPassengerMock> enrollStudent({
    required String name,
    required String parentName,
    required String parentPhone,
    required String pickupAddress,
    required BusMock bus,
    String schoolName = 'Colegio Ángel María Herrera',
    double monthlyFee = 65.0,
    double? pickupLatitude,
    double? pickupLongitude,
    String? parentId,
  }) async {
    if (!canEnrollStudent(bus)) {
      throw StateError(
        'Capacidad máxima alcanzada en ${bus.code} (${bus.seatsOccupied}/${bus.capacity} cupos ocupados).',
      );
    }

    final existingRows = await _supabase
        .from('estudiantes_pasajeros')
        .select('id')
        .eq('autobus_codigo', bus.code)
        .timeout(const Duration(seconds: 3));
    final nextOrder = (existingRows as List).length + 1;

    final resolvedParentId = (parentId != null && parentId.isNotEmpty)
        ? parentId
        : _supabase.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'nombre': name.trim(),
      'padre_nombre': parentName.trim(),
      'padre_telefono': parentPhone.trim(),
      'colegio': schoolName.trim(),
      'direccion_recogida': pickupAddress.trim(),
      'autobus_codigo': bus.code,
      'orden': nextOrder,
      'cuota_mensual': monthlyFee,
      'estado_pago': 'Al día',
      if (resolvedParentId != null && resolvedParentId.isNotEmpty)
        'padre_id': resolvedParentId,
      'latitud_recogida': ?pickupLatitude,
      'longitud_recogida': ?pickupLongitude,
    };

    final inserted = await _supabase
        .from('estudiantes_pasajeros')
        .insert(payload)
        .select()
        .single()
        .timeout(const Duration(seconds: 5));

    await _syncBusSeatCount(bus.code);

    var created = StudentPassengerMock.fromMap(Map<String, dynamic>.from(inserted));
    if (pickupLatitude != null && pickupLongitude != null) {
      created = created.copyWith(
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
      );
      await _syncStudentStopInParadasRuta(
        studentId: created.id,
        studentName: created.name,
        pickupAddress: created.pickupAddress,
        busCode: bus.code,
        order: nextOrder,
        latitude: pickupLatitude,
        longitude: pickupLongitude,
      );
    }

    _localSessionOverrides[created.id] = created;
    _locationUpdatesController.add(created);
    return created;
  }

  /// PUT unificado para actualizar cualquier campo de un estudiante (`estudiantes_pasajeros`),
  /// sincronizar `paradas_ruta`, recalcular `asientos_ocupados` si cambió de bus
  /// y emitir el cambio en `locationUpdatesStream`.
  Future<StudentPassengerMock?> updateStudent({
    required int studentId,
    String? name,
    String? parentName,
    String? parentPhone,
    String? pickupAddress,
    String? schoolName,
    String? busCode,
    double? pickupLatitude,
    double? pickupLongitude,
    String? paymentStatus,
  }) async {
    try {
      final previousRow = await _supabase
          .from('estudiantes_pasajeros')
          .select('autobus_codigo')
          .eq('id', studentId)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      final previousBusCode = previousRow?['autobus_codigo']?.toString() ?? '';

      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['nombre'] = name.trim();
      }
      if (parentName != null && parentName.trim().isNotEmpty) {
        updates['padre_nombre'] = parentName.trim();
      }
      if (parentPhone != null && parentPhone.trim().isNotEmpty) {
        updates['padre_telefono'] = parentPhone.trim();
      }
      if (pickupAddress != null && pickupAddress.trim().isNotEmpty) {
        updates['direccion_recogida'] = pickupAddress.trim();
      }
      if (schoolName != null && schoolName.trim().isNotEmpty) {
        updates['colegio'] = schoolName.trim();
      }
      if (busCode != null && busCode.trim().isNotEmpty) {
        updates['autobus_codigo'] = busCode.trim().toUpperCase();
      }
      if (pickupLatitude != null) {
        updates['latitud_recogida'] = pickupLatitude;
      }
      if (pickupLongitude != null) {
        updates['longitud_recogida'] = pickupLongitude;
      }
      if (paymentStatus != null && paymentStatus.trim().isNotEmpty) {
        updates['estado_pago'] = paymentStatus.trim();
      }

      if (updates.isEmpty) return await getStudentById(studentId);

      final updatedRow = await _supabase
          .from('estudiantes_pasajeros')
          .update(updates)
          .eq('id', studentId)
          .select(_studentColumns)
          .maybeSingle()
          .timeout(const Duration(seconds: 4));

      if (updatedRow == null) return null;

      final student = StudentPassengerMock.fromMap(Map<String, dynamic>.from(updatedRow));

      // Sincronizar parada en `paradas_ruta` si hay coordenadas nuevas o ya existentes
      final lat = pickupLatitude ?? student.pickupLatitude;
      final lng = pickupLongitude ?? student.pickupLongitude;
      if (lat != null && lng != null) {
        await _syncStudentStopInParadasRuta(
          studentId: student.id,
          studentName: student.name,
          pickupAddress: student.pickupAddress,
          busCode: student.busCode,
          order: student.order,
          latitude: lat,
          longitude: lng,
        );
      }

      // Si cambió de autobús, recalcular asientos_ocupados en ambos
      final newBusCode = student.busCode;
      if (previousBusCode.isNotEmpty && previousBusCode != newBusCode) {
        await Future.wait([
          _syncBusSeatCount(previousBusCode),
          _syncBusSeatCount(newBusCode),
        ]);
      }

      // Mantener sincronizado el teléfono en `perfiles` del tutor si existe `padre_id`
      if (student.parentId != null &&
          student.parentId!.isNotEmpty &&
          ((parentName != null && parentName.trim().isNotEmpty) ||
              (parentPhone != null && parentPhone.trim().isNotEmpty))) {
        try {
          await _supabase
              .from('perfiles')
              .update({
                if (parentName != null && parentName.trim().isNotEmpty)
                  'nombre': parentName.trim(),
                if (parentPhone != null && parentPhone.trim().isNotEmpty)
                  'telefono': parentPhone.trim(),
              })
              .eq('id', student.parentId!)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Aviso sincronizando perfil tutor: $e');
        }
      }

      _localSessionOverrides[student.id] = student;
      _locationUpdatesController.add(student);
      return student;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en updateStudent($studentId) [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error en updateStudent($studentId): $e');
      rethrow;
    }
  }

  /// Guarda o actualiza las coordenadas exactas de recogida (GPS o ingreso manual) en Supabase
  /// y emite el evento en `locationUpdatesStream` para sincronizar todos los módulos al instante.
  Future<StudentPassengerMock?> updateStudentPickupLocation({
    required int studentId,
    required double latitude,
    required double longitude,
    String? pickupAddress,
    String? busCode,
  }) {
    return updateStudent(
      studentId: studentId,
      pickupAddress: pickupAddress,
      busCode: busCode,
      pickupLatitude: latitude,
      pickupLongitude: longitude,
    );
  }

  /// Sincroniza el punto de recogida del estudiante en `public.paradas_ruta` (columnas `latitud` y `longitud`).
  Future<void> _syncStudentStopInParadasRuta({
    required int studentId,
    required String studentName,
    required String pickupAddress,
    required String busCode,
    required int order,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final stopCode = 'EST-$studentId';
      final existing = await _supabase
          .from('paradas_ruta')
          .select('id')
          .eq('codigo', stopCode)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (existing != null && existing['id'] != null) {
        await _supabase
            .from('paradas_ruta')
            .update({
              'nombre': 'Domicilio: $studentName',
              'referencia': pickupAddress,
              'autobus_codigo': busCode,
              'orden': order,
              'latitud': latitude,
              'longitud': longitude,
            })
            .eq('id', existing['id'])
            .timeout(const Duration(seconds: 3));
      } else {
        await _supabase.from('paradas_ruta').insert({
          'autobus_codigo': busCode,
          'codigo': stopCode,
          'nombre': 'Domicilio: $studentName',
          'referencia': pickupAddress,
          'orden': order,
          'distancia_km': order * 0.8,
          'latitud': latitude,
          'longitud': longitude,
          'is_favorite': true,
        }).timeout(const Duration(seconds: 3));
      }
    } catch (e) {
      debugPrint('Aviso sincronizando paradas_ruta: $e');
    }
  }

  /// Actualiza el estado de pago de la mensualidad de un estudiante (RF-06)
  Future<StudentPassengerMock?> updatePaymentStatus({
    required int studentId,
    required String status,
  }) async {
    try {
      return await updateStudent(studentId: studentId, paymentStatus: status);
    } catch (e) {
      debugPrint('Error en updatePaymentStatus: $e');
      return null;
    }
  }

  /// Obtiene las coordenadas registradas en `paradas_ruta` indexadas por `EST-{studentId}`
  Future<Map<int, ({double lat, double lng, String? reference})>>
      _fetchStudentStopCoordinatesMap() async {
    final coordsMap = <int, ({double lat, double lng, String? reference})>{};
    try {
      final stopsResponse = await _supabase
          .from('paradas_ruta')
          .select('codigo, latitud, longitud, referencia')
          .like('codigo', 'EST-%')
          .timeout(const Duration(seconds: 3));

      for (final row in (stopsResponse as List)) {
        final code = row['codigo']?.toString() ?? '';
        final idPart = int.tryParse(code.replaceFirst('EST-', ''));
        final lat = (row['latitud'] as num?)?.toDouble();
        final lng = (row['longitud'] as num?)?.toDouble();
        final ref = row['referencia']?.toString();
        if (idPart != null && lat != null && lng != null) {
          coordsMap[idPart] = (lat: lat, lng: lng, reference: ref);
        }
      }
    } catch (e) {
      debugPrint('Aviso consultando paradas_ruta: $e');
    }
    return coordsMap;
  }

  StudentPassengerMock _enrichWithCoordinates(
    StudentPassengerMock student,
    Map<int, ({double lat, double lng, String? reference})> stopsCoordsMap,
  ) {
    var enriched = student;

    final fromStop = stopsCoordsMap[student.id];
    if (fromStop != null) {
      enriched = enriched.copyWith(
        pickupLatitude: enriched.pickupLatitude ?? fromStop.lat,
        pickupLongitude: enriched.pickupLongitude ?? fromStop.lng,
        pickupAddress:
            (enriched.pickupAddress.trim().isEmpty &&
                    fromStop.reference != null &&
                    fromStop.reference!.trim().isNotEmpty)
                ? fromStop.reference!
                : enriched.pickupAddress,
      );
    }

    return enriched;
  }

  /// Obtiene los estudiantes asignados a un autobús con su asistencia del día combinada
  Future<List<StudentPassengerMock>> getStudentsByBus(String busCode) async {
    try {
      final cleanedBus = busCode.trim().toUpperCase();
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select(_studentColumns)
            .eq('autobus_codigo', cleanedBus)
            .order('orden', ascending: true)
            .timeout(const Duration(seconds: 3)),
        _supabase
            .from('asistencia_diaria')
            .select(_attendanceColumns)
            .eq('fecha', todayStr)
            .timeout(const Duration(seconds: 3)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final studentsList = results[0] as List;
      if (studentsList.isEmpty) return [];

      final attendanceResponse = results[1] as List;
      final stopsCoordsMap =
          results[2] as Map<int, ({double lat, double lng, String? reference})>;

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in attendanceResponse) {
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
        final baseStudent =
            StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
        return _enrichWithCoordinates(baseStudent, stopsCoordsMap);
      }).toList();
    } catch (e) {
      debugPrint('Error en getStudentsByBus($busCode): $e');
      return [];
    }
  }

  /// Obtiene el o los estudiantes a cargo del padre autenticado en paralelo
  Future<List<StudentPassengerMock>> getStudentsByParent(String parentId) async {
    if (parentId.trim().isEmpty) return [];
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select(_studentColumns)
            .eq('padre_id', parentId.trim())
            .order('id', ascending: true)
            .timeout(const Duration(seconds: 3)),
        _supabase
            .from('asistencia_diaria')
            .select(_attendanceColumns)
            .eq('fecha', todayStr)
            .timeout(const Duration(seconds: 3)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final studentsList = results[0] as List;
      if (studentsList.isEmpty) return [];

      final attendanceResponse = results[1] as List;
      final stopsCoordsMap =
          results[2] as Map<int, ({double lat, double lng, String? reference})>;

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in attendanceResponse) {
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
        final baseStudent =
            StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
        final enriched = _enrichWithCoordinates(baseStudent, stopsCoordsMap);
        _localSessionOverrides[enriched.id] = enriched;
        return enriched;
      }).toList();
    } catch (e) {
      debugPrint('Error en getStudentsByParent: $e');
      return [];
    }
  }

  /// Retorna el estudiante principal vinculado al `parentId` autenticado (o `null` si aún no registra hijos).
  Future<StudentPassengerMock?> getPrimaryStudent(String? parentId) async {
    if (parentId != null && parentId.trim().isNotEmpty) {
      final list = await getStudentsByParent(parentId.trim());
      if (list.isNotEmpty) return list.first;
    }
    return null;
  }

  /// Obtiene todos los estudiantes registrados para el control del transportista en paralelo
  Future<List<StudentPassengerMock>> getAllStudents() async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select(_studentColumns)
            .order('autobus_codigo', ascending: true)
            .order('orden', ascending: true)
            .timeout(const Duration(seconds: 3)),
        _supabase
            .from('asistencia_diaria')
            .select(_attendanceColumns)
            .eq('fecha', todayStr)
            .timeout(const Duration(seconds: 3)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final response = results[0] as List;
      final attendanceResponse = results[1] as List;
      final stopsCoordsMap =
          results[2] as Map<int, ({double lat, double lng, String? reference})>;

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in attendanceResponse) {
        final id = att['estudiante_id'] is int
            ? att['estudiante_id']
            : int.tryParse(att['estudiante_id'].toString()) ?? 0;
        attendanceMap[id] = att as Map<String, dynamic>;
      }

      return response.map((row) {
        final id = row['id'] is int
            ? row['id']
            : int.tryParse(row['id'].toString()) ?? 0;
        final baseStudent = StudentPassengerMock.fromMap(
          row as Map<String, dynamic>,
          attendanceMap[id],
        );
        return _enrichWithCoordinates(baseStudent, stopsCoordsMap);
      }).toList();
    } catch (e) {
      debugPrint('Error en getAllStudents: $e');
      return [];
    }
  }

  /// Catálogo completo desde PostgreSQL (`estudiantes_pasajeros` + `perfiles` rol `student`)
  /// para el Select con Búsqueda Avanzada del Transportista.
  Future<List<StudentPassengerMock>> getSearchableStudentsCatalog() async {
    final byIdOrKey = <String, StudentPassengerMock>{};

    try {
      final results = await Future.wait([
        getAllStudents(),
        _supabase
            .from('perfiles')
            .select('id, nombre, email, telefono')
            .eq('rol', 'student')
            .timeout(const Duration(seconds: 3)),
      ]);

      final dbStudents = results[0] as List<StudentPassengerMock>;
      final linkedParentIds = <String>{};
      for (final s in dbStudents) {
        byIdOrKey['db-${s.id}'] = s;
        if (s.parentId != null && s.parentId!.isNotEmpty) {
          linkedParentIds.add(s.parentId!);
        }
      }

      final profileRows = (results[1] as List).cast<Map<String, dynamic>>();
      int syntheticCounter = 1;
      for (final profile in profileRows) {
        final profileId = profile['id']?.toString() ?? '';
        final rawName = profile['nombre']?.toString().trim() ?? '';
        if (rawName.isEmpty) continue;
        // Evitar duplicar un perfil que ya tiene estudiante vinculado
        if (profileId.isNotEmpty && linkedParentIds.contains(profileId)) continue;

        final alreadyExists = byIdOrKey.values.any(
          (s) => s.name.trim().toLowerCase() == rawName.toLowerCase(),
        );
        if (!alreadyExists) {
          byIdOrKey['profile-$profileId'] = StudentPassengerMock(
            id: -(syntheticCounter++),
            parentId: profileId.isNotEmpty ? profileId : null,
            name: rawName,
            parentName: rawName,
            parentPhone: profile['telefono']?.toString() ?? '',
            schoolName: 'Colegio Ángel María Herrera',
            pickupAddress: '',
            busCode: 'SIN ASIGNAR',
            routeCode: 'SIN ASIGNAR',
            order: byIdOrKey.length + 1,
            status: PassengerStatus.waiting,
            monthlyFee: 65.0,
            paymentStatus: 'Al día',
          );
        }
      }
    } catch (e) {
      debugPrint('Error en getSearchableStudentsCatalog: $e');
    }

    return byIdOrKey.values.toList();
  }

  /// Asigna un estudiante ya existente del buscador a un autobús (actualizando su unidad y datos),
  /// o lo matricula como nuevo si aún no existía en `estudiantes_pasajeros`.
  Future<StudentPassengerMock> assignOrEnrollStudent({
    StudentPassengerMock? existingStudent,
    required String name,
    required String parentName,
    required String parentPhone,
    required String pickupAddress,
    required BusMock bus,
    String schoolName = 'Colegio Ángel María Herrera',
    String? parentId,
  }) async {
    if (!canEnrollStudent(bus)) {
      throw StateError(
        'Capacidad máxima alcanzada en ${bus.code} (${bus.seatsOccupied}/${bus.capacity} cupos ocupados).',
      );
    }

    // Si es un estudiante ya existente en PostgreSQL (`id > 0`)
    if (existingStudent != null && existingStudent.id > 0) {
      final updated = await updateStudent(
        studentId: existingStudent.id,
        name: name,
        parentName: parentName,
        parentPhone: parentPhone,
        pickupAddress: pickupAddress,
        busCode: bus.code,
        schoolName: schoolName,
      );
      if (updated != null) return updated;
    }

    return enrollStudent(
      name: name,
      parentName: parentName,
      parentPhone: parentPhone,
      pickupAddress: pickupAddress,
      bus: bus,
      schoolName: schoolName,
      parentId: parentId ?? existingStudent?.parentId,
      pickupLatitude: existingStudent?.pickupLatitude,
      pickupLongitude: existingStudent?.pickupLongitude,
    );
  }

  /// Calcula el resumen financiero y métricas de aforo reales desde PostgreSQL
  Future<FleetFinancialSummary> getFleetFinancialSummary([String? ownerId]) async {
    try {
      var busesQuery = _supabase.from('autobuses').select('codigo, capacidad, asientos_ocupados');
      if (ownerId != null && ownerId.isNotEmpty) {
        busesQuery = busesQuery.eq('dueno_id', ownerId);
      }

      final results = await Future.wait([
        busesQuery.timeout(const Duration(seconds: 3)),
        _supabase
            .from('estudiantes_pasajeros')
            .select('autobus_codigo, cuota_mensual, estado_pago')
            .timeout(const Duration(seconds: 3)),
      ]);

      final busesData = results[0] as List;
      final busCodes = <String>{};
      int totalSeats = 0;
      int occupiedSeats = 0;
      for (final b in busesData) {
        final code = b['codigo']?.toString() ?? '';
        if (code.isNotEmpty) busCodes.add(code);
        totalSeats += (b['capacidad'] as num?)?.toInt() ?? 0;
        occupiedSeats += (b['asientos_ocupados'] as num?)?.toInt() ?? 0;
      }

      final allStudents = results[1] as List;
      final filteredStudents = (ownerId != null && busCodes.isNotEmpty)
          ? allStudents.where((s) => busCodes.contains(s['autobus_codigo']?.toString())).toList()
          : allStudents;

      double totalRevenue = 0.0;
      double pendingRevenue = 0.0;
      int pendingPaymentsCount = 0;

      for (final s in filteredStudents) {
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
        totalSeats: totalSeats,
        occupiedSeats: occupiedSeats > 0 ? occupiedSeats : filteredStudents.length,
        totalRevenue: totalRevenue,
        pendingRevenue: pendingRevenue,
        pendingPaymentsCount: pendingPaymentsCount,
        totalStudents: filteredStudents.length,
      );
    } catch (e) {
      debugPrint('Error calculando FleetFinancialSummary: $e');
      return FleetFinancialSummary.empty;
    }
  }

  /// Actualiza los datos de contacto, dirección o coordenadas de un estudiante (RF-02)
  Future<StudentPassengerMock?> updateStudentProfile({
    required int studentId,
    String? name,
    String? parentName,
    String? parentPhone,
    String? pickupAddress,
    String? schoolName,
    double? pickupLatitude,
    double? pickupLongitude,
  }) {
    return updateStudent(
      studentId: studentId,
      name: name,
      parentName: parentName,
      parentPhone: parentPhone,
      pickupAddress: pickupAddress,
      schoolName: schoolName,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
    );
  }

  /// DELETE seguro de un estudiante por ID con recálculo de aforo en su autobús
  Future<bool> deleteStudent(int studentId) async {
    if (studentId <= 0) return false;
    try {
      final existing = await _supabase
          .from('estudiantes_pasajeros')
          .select('autobus_codigo')
          .eq('id', studentId)
          .maybeSingle()
          .timeout(const Duration(seconds: 3));

      if (existing == null) return false;
      final busCode = existing['autobus_codigo']?.toString() ?? '';

      await _supabase
          .from('paradas_ruta')
          .delete()
          .eq('codigo', 'EST-$studentId')
          .timeout(const Duration(seconds: 3));

      await _supabase
          .from('estudiantes_pasajeros')
          .delete()
          .eq('id', studentId)
          .timeout(const Duration(seconds: 4));

      _localSessionOverrides.remove(studentId);
      if (busCode.isNotEmpty) {
        await _syncBusSeatCount(busCode);
      }
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Error PostgREST en deleteStudent($studentId) [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error en deleteStudent($studentId): $e');
      rethrow;
    }
  }
}
