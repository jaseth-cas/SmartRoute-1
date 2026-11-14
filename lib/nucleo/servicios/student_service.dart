import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

/// Servicio para la gestión de estudiantes matriculados, asignación de cupos,
/// coordenadas exactas de recogida (GPS / manual) y resumen financiero.
class StudentService {
  final SupabaseClient? _injectedClient;

  StudentService({SupabaseClient? supabaseClient}) : _injectedClient = supabaseClient;

  SupabaseClient get _supabase => _injectedClient ?? SupabaseConfig.client;

  /// Verifica si un autobús aún dispone de asientos físicos libres antes de matricular (RF-05)
  bool canEnrollStudent(BusMock bus) {
    return bus.hasAvailableSeats;
  }

  /// Matricula un nuevo estudiante en un autobús validando el control de aforo / sobrecupo (RF-05)
  Future<StudentPassengerMock> enrollStudent({
    required String name,
    required String parentName,
    required String parentPhone,
    required String pickupAddress,
    required BusMock bus,
    String schoolName = 'Colegio San José',
    double monthlyFee = 65.0,
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    if (!canEnrollStudent(bus)) {
      throw StateError(
        'Capacidad máxima alcanzada en ${bus.code} (${bus.seatsOccupied}/${bus.capacity} cupos ocupados).',
      );
    }

    final currentBusStudents = MockData.getPassengersByBus(bus.code);
    final nextOrder = currentBusStudents.length + 1;
    final newId = (MockData.passengers.isEmpty
            ? 0
            : MockData.passengers.map((p) => p.id).reduce((a, b) => a > b ? a : b)) +
        1;

    final newStudent = StudentPassengerMock(
      id: newId,
      name: name.trim(),
      parentName: parentName.trim(),
      parentPhone: parentPhone.trim(),
      schoolName: schoolName.trim(),
      pickupAddress: pickupAddress.trim(),
      busCode: bus.code,
      routeCode: 'R-UB',
      order: nextOrder,
      status: PassengerStatus.waiting,
      monthlyFee: monthlyFee,
      paymentStatus: 'Al día',
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
    );

    MockData.passengers.add(newStudent);
    final busIndex = MockData.buses.indexWhere((b) => b.code == bus.code);
    if (busIndex != -1) {
      MockData.buses[busIndex] = MockData.buses[busIndex].copyWith(
        seatsOccupied: MockData.buses[busIndex].seatsOccupied + 1,
      );
    }

    try {
      final basePayload = <String, dynamic>{
        'nombre': newStudent.name,
        'padre_nombre': newStudent.parentName,
        'padre_telefono': newStudent.parentPhone,
        'colegio': newStudent.schoolName,
        'direccion_recogida': newStudent.pickupAddress,
        'autobus_codigo': bus.code,
        'orden': nextOrder,
        'cuota_mensual': monthlyFee,
        'estado_pago': 'Al día',
      };

      Map<String, dynamic>? inserted;
      try {
        final payloadWithCoords = <String, dynamic>{
          ...basePayload,
        };
        if (pickupLatitude != null) payloadWithCoords['latitud_recogida'] = pickupLatitude;
        if (pickupLongitude != null) payloadWithCoords['longitud_recogida'] = pickupLongitude;
        inserted = await _supabase
            .from('estudiantes_pasajeros')
            .insert(payloadWithCoords)
            .select()
            .maybeSingle();
      } catch (_) {
        // Fallback si la instancia remota aún no tiene las columnas latitud_recogida / longitud_recogida
        inserted = await _supabase
            .from('estudiantes_pasajeros')
            .insert(basePayload)
            .select()
            .maybeSingle();
      }

      await _supabase
          .from('autobuses')
          .update({'asientos_ocupados': bus.seatsOccupied + 1})
          .eq('codigo', bus.code);

      if (pickupLatitude != null && pickupLongitude != null) {
        final createdId = inserted != null
            ? (inserted['id'] is int ? inserted['id'] as int : int.tryParse(inserted['id'].toString()) ?? newId)
            : newId;
        await _syncStudentStopInParadasRuta(
          studentId: createdId,
          studentName: newStudent.name,
          pickupAddress: newStudent.pickupAddress,
          busCode: bus.code,
          order: nextOrder,
          latitude: pickupLatitude,
          longitude: pickupLongitude,
        );
      }

      if (inserted != null) {
        return StudentPassengerMock.fromMap(inserted).copyWith(
          pickupLatitude: pickupLatitude,
          pickupLongitude: pickupLongitude,
        );
      }
    } catch (e) {
      debugPrint('Aviso en enrollStudent Supabase: $e');
    }

    return newStudent;
  }

  /// Guarda o actualiza las coordenadas exactas de recogida (GPS o ingreso manual) en Supabase y memoria local.
  Future<StudentPassengerMock?> updateStudentPickupLocation({
    required int studentId,
    required double latitude,
    required double longitude,
    String? pickupAddress,
    String? busCode,
  }) async {
    final updatedLocal = MockData.updateStudentProfile(
      studentId: studentId,
      pickupAddress: pickupAddress?.trim(),
      pickupLatitude: latitude,
      pickupLongitude: longitude,
    );

    // Actualizar también la lista local de paradas si existe una parada asociada al estudiante
    final stopCode = 'EST-$studentId';
    final stopIndex = MockData.stops.indexWhere((s) => s.stopCode == stopCode);
    if (stopIndex != -1) {
      MockData.stops[stopIndex] = MockData.stops[stopIndex].copyWith(
        latitude: latitude,
        longitude: longitude,
        reference: pickupAddress ?? MockData.stops[stopIndex].reference,
      );
    } else if (updatedLocal != null) {
      MockData.stops.add(
        StopMock(
          id: 100 + studentId,
          routeCode: updatedLocal.routeCode,
          stopCode: stopCode,
          name: 'Casa de ${updatedLocal.name}',
          reference: pickupAddress ?? updatedLocal.pickupAddress,
          order: updatedLocal.order,
          distanceFromStartKm: updatedLocal.order * 0.8,
          latitude: latitude,
          longitude: longitude,
          isFavorite: true,
        ),
      );
    }

    try {
      final updatesWithCoords = <String, dynamic>{
        'latitud_recogida': latitude,
        'longitud_recogida': longitude,
        if (pickupAddress != null && pickupAddress.trim().isNotEmpty)
          'direccion_recogida': pickupAddress.trim(),
      };

      try {
        await _supabase
            .from('estudiantes_pasajeros')
            .update(updatesWithCoords)
            .eq('id', studentId);
      } catch (_) {
        if (pickupAddress != null && pickupAddress.trim().isNotEmpty) {
          await _supabase
              .from('estudiantes_pasajeros')
              .update({'direccion_recogida': pickupAddress.trim()})
              .eq('id', studentId);
        }
      }

      await _syncStudentStopInParadasRuta(
        studentId: studentId,
        studentName: updatedLocal?.name ?? 'Estudiante #$studentId',
        pickupAddress: pickupAddress ?? updatedLocal?.pickupAddress ?? 'Domicilio Escolar',
        busCode: busCode ?? updatedLocal?.busCode ?? 'BUS-01',
        order: updatedLocal?.order ?? 1,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('Aviso en updateStudentPickupLocation Supabase: $e');
    }

    return updatedLocal;
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
          .maybeSingle();

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
            .eq('id', existing['id']);
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
        });
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
    final updatedLocal = MockData.updatePaymentStatus(studentId, status);

    try {
      await _supabase
          .from('estudiantes_pasajeros')
          .update({'estado_pago': status})
          .eq('id', studentId);
    } catch (e) {
      debugPrint('Aviso en updatePaymentStatus Supabase: $e');
    }

    return updatedLocal;
  }

  /// Obtiene las coordenadas registradas en `paradas_ruta` indexadas por `EST-{studentId}`
  Future<Map<int, ({double lat, double lng})>> _fetchStudentStopCoordinatesMap() async {
    final coordsMap = <int, ({double lat, double lng})>{};
    try {
      final stopsResponse = await _supabase
          .from('paradas_ruta')
          .select('codigo, latitud, longitud')
          .like('codigo', 'EST-%')
          .timeout(const Duration(milliseconds: 2500));

      for (final row in (stopsResponse as List)) {
        final code = row['codigo']?.toString() ?? '';
        final idPart = int.tryParse(code.replaceFirst('EST-', ''));
        final lat = (row['latitud'] as num?)?.toDouble();
        final lng = (row['longitud'] as num?)?.toDouble();
        if (idPart != null && lat != null && lng != null) {
          coordsMap[idPart] = (lat: lat, lng: lng);
        }
      }
    } catch (_) {}
    return coordsMap;
  }

  StudentPassengerMock _enrichWithCoordinates(
    StudentPassengerMock student,
    Map<int, ({double lat, double lng})> stopsCoordsMap,
  ) {
    if (student.pickupLatitude != null && student.pickupLongitude != null) {
      return student;
    }
    final fromStop = stopsCoordsMap[student.id];
    if (fromStop != null) {
      return student.copyWith(
        pickupLatitude: fromStop.lat,
        pickupLongitude: fromStop.lng,
      );
    }
    final localMatch = MockData.passengers.where((p) => p.id == student.id).firstOrNull;
    if (localMatch != null && localMatch.pickupLatitude != null && localMatch.pickupLongitude != null) {
      return student.copyWith(
        pickupLatitude: localMatch.pickupLatitude,
        pickupLongitude: localMatch.pickupLongitude,
      );
    }
    return student;
  }

  /// Obtiene los estudiantes asignados a un autobús con su asistencia del día combinada
  /// ejecutando las 3 consultas en paralelo (`Future.wait`) con timeout rápido de 2.5s.
  Future<List<StudentPassengerMock>> getStudentsByBus(String busCode) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select()
            .eq('autobus_codigo', busCode)
            .order('orden', ascending: true)
            .timeout(const Duration(milliseconds: 2500)),
        _supabase
            .from('asistencia_diaria')
            .select()
            .eq('fecha', todayStr)
            .timeout(const Duration(milliseconds: 2500)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final studentsList = results[0] as List;
      if (studentsList.isEmpty) return MockData.getPassengersByBus(busCode);

      final attendanceResponse = results[1] as List;
      final stopsCoordsMap = results[2] as Map<int, ({double lat, double lng})>;

      final attendanceMap = <int, Map<String, dynamic>>{};
      for (final att in attendanceResponse) {
        final id = att['estudiante_id'] is int
            ? att['estudiante_id']
            : int.tryParse(att['estudiante_id'].toString()) ?? 0;
        attendanceMap[id] = att as Map<String, dynamic>;
      }

      // Mapear cada estudiante con su asistencia del día y sus coordenadas de recogida
      return studentsList.map((row) {
        final id = row['id'] is int
            ? row['id']
            : int.tryParse(row['id'].toString()) ?? 0;
        final att = attendanceMap[id];
        final baseStudent = StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
        return _enrichWithCoordinates(baseStudent, stopsCoordsMap);
      }).toList();
    } catch (e) {
      debugPrint('Error en getStudentsByBus: $e');
      return MockData.getPassengersByBus(busCode);
    }
  }

  /// Obtiene el o los estudiantes a cargo del padre autenticado en paralelo
  Future<List<StudentPassengerMock>> getStudentsByParent(String parentId) async {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select()
            .eq('padre_id', parentId)
            .timeout(const Duration(milliseconds: 2500)),
        _supabase
            .from('asistencia_diaria')
            .select()
            .eq('fecha', todayStr)
            .timeout(const Duration(milliseconds: 2500)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final studentsList = results[0] as List;
      if (studentsList.isEmpty) return [];

      final attendanceResponse = results[1] as List;
      final stopsCoordsMap = results[2] as Map<int, ({double lat, double lng})>;

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
        final baseStudent = StudentPassengerMock.fromMap(row as Map<String, dynamic>, att);
        return _enrichWithCoordinates(baseStudent, stopsCoordsMap);
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

  /// Obtiene todos los estudiantes registrados para el control del transportista en paralelo
  Future<List<StudentPassengerMock>> getAllStudents() async {
    try {
      final results = await Future.wait([
        _supabase
            .from('estudiantes_pasajeros')
            .select()
            .order('orden', ascending: true)
            .timeout(const Duration(milliseconds: 2500)),
        _fetchStudentStopCoordinatesMap(),
      ]);

      final response = results[0] as List;
      final stopsCoordsMap = results[1] as Map<int, ({double lat, double lng})>;

      final list = response.map((row) {
        final baseStudent = StudentPassengerMock.fromMap(row as Map<String, dynamic>);
        return _enrichWithCoordinates(baseStudent, stopsCoordsMap);
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

  /// Actualiza los datos de contacto, dirección o coordenadas de un estudiante (RF-02)
  Future<void> updateStudentProfile({
    required int studentId,
    String? name,
    String? pickupAddress,
    String? parentPhone,
    String? schoolName,
    double? pickupLatitude,
    double? pickupLongitude,
  }) async {
    MockData.updateStudentProfile(
      studentId: studentId,
      name: name?.trim(),
      pickupAddress: pickupAddress?.trim(),
      parentPhone: parentPhone?.trim(),
      schoolName: schoolName?.trim(),
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
    );

    if (pickupLatitude != null && pickupLongitude != null) {
      await updateStudentPickupLocation(
        studentId: studentId,
        latitude: pickupLatitude,
        longitude: pickupLongitude,
        pickupAddress: pickupAddress,
      );
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) updates['nombre'] = name.trim();
      if (pickupAddress != null && pickupAddress.trim().isNotEmpty) {
        updates['direccion_recogida'] = pickupAddress.trim();
      }
      if (parentPhone != null && parentPhone.trim().isNotEmpty) {
        updates['padre_telefono'] = parentPhone.trim();
      }
      if (schoolName != null && schoolName.trim().isNotEmpty) {
        updates['colegio'] = schoolName.trim();
      }

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
