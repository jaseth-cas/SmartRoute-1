import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartroute_flutter/main.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/route_optimizer_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/servicios/telemetry_simulation_service.dart';
import 'package:smartroute_flutter/nucleo/utilidades/coordinate_parser.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

http.Response _jsonResp(http.Request req, Object? data, {int status = 200}) {
  return http.Response(
    data is String ? data : jsonEncode(data),
    status,
    headers: const {'content-type': 'application/json'},
    request: req,
  );
}

void main() {
  group('Módulo Núcleo - Arranque, Modelos, Servicios de Flota/OSRM y Utilidades', () {
    testWidgets('SmartRouteApp inicializa árbol raíz con SessionManager sin errores', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()),
          ],
          child: const SmartRouteApp(),
        ),
      );
      await tester.pump();
      expect(find.text('SmartRoute'), findsWidgets);
    });

    test('Modelos, Validators, AppConstants y CoordinateParser cubren reglas de Penonomé', () {
      final bus = BusMock.fromMap({
        'id': 1,
        'codigo': 'BUS-01',
        'placa': 'TBX-492',
        'modelo': 'Toyota Coaster',
        'capacidad': 16,
        'asientos_ocupados': 4,
        'estado': 'En recorrido',
        'latitud_actual': 8.5186,
        'longitud_actual': -80.3572,
        'is_verified': true,
      });
      expect(bus.availableSeats, 12);
      expect(bus.hasAvailableSeats, isTrue);

      final onboard = StudentPassengerMock.fromMap(
        {
          'id': 1,
          'nombre': 'Mateo Gómez',
          'padre_nombre': 'Carlos Gómez',
          'padre_telefono': '+507 6300-4567',
          'colegio': 'Colegio Ángel María Herrera',
          'direccion_recogida': 'Vía Sonadora',
          'autobus_codigo': 'BUS-01',
          'orden': 1,
        },
        {'estado': 'onboard', 'metodo_abordaje': 'Biometría Facial AI'},
      );
      expect(onboard.status, PassengerStatus.onboard);
      expect(onboard.boardingMethod, 'Biometría Facial AI');

      expect(Validators.validateEmail('padre1@smartroute.com'), isNull);
      expect(Validators.validateEmail('invalido'), isNotNull);
      expect(Validators.validatePlate('TBX-492'), isNull);
      expect(Validators.validateBusCode('BUS-01'), isNull);
      expect(Validators.validateCapacity('20'), isNull);

      final sanAgustin = AppConstants.resolveSchoolPoint('Colegio San Agustín');
      expect(sanAgustin.latitude, inInclusiveRange(8.45, 8.60));
      expect(AppConstants.calculateEtaMinutes(distanceKm: 15, speedKmH: 0), 30);

      final dms = CoordinateParser.parseWithDetails('8°31\'00"N 80°21\'00"O');
      expect(dms.isSuccess, isTrue);
      expect(dms.format, CoordinateFormatType.dms);
      expect(CoordinateParser.validate('95.0000, -80.3500'), contains('Latitud fuera de rango'));
    });

    test('BusService opera CRUD/rutas/paradas y propaga fallos de red en 54321', () async {
      final mockClient = MockClient((req) async {
        if (req.url.path == '/rest/v1/autobuses' && req.method == 'POST') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(req, {'id': 3, ...body}, status: 201);
        }
        if (req.url.path == '/rest/v1/autobuses' && req.method == 'GET') {
          return _jsonResp(req, [
            {
              'id': 1,
              'codigo': 'BUS-01',
              'placa': 'TBX-492',
              'modelo': 'Toyota Coaster',
              'capacidad': 16,
              'asientos_ocupados': 4,
              'estado': 'En recorrido',
              'colegio_asignado': 'Colegio Ángel María Herrera',
              'nombre_ruta': 'Ruta Norte',
              'is_verified': true,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {'id': 'a0000000-0000-0000-0000-000000000001', 'nombre': 'Don Fernando Gómez'},
          ]);
        }
        if (req.url.path == '/rest/v1/paradas_ruta' && req.method == 'GET') {
          return _jsonResp(req, [
            {
              'id': 1,
              'autobus_codigo': 'BUS-01',
              'codigo': 'P-B01-01',
              'nombre': 'Vía Sonadora Norte',
              'referencia': 'Entrada Sonadora',
              'orden': 1,
              'distancia_km': 0.0,
              'latitud': 8.5284,
              'longitud': -80.3582,
              'is_favorite': true,
            },
          ]);
        }
        return _jsonResp(req, []);
      });

      final service = BusService(
        supabaseClient: SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.anonKey,
          httpClient: mockClient,
        ),
      );

      expect(service.normalizeBusCode('r-bus-01'), 'BUS-01');
      final created = await service.createBus(
        code: 'r-bus 03',
        plate: 'pnm-303',
        model: 'Hyundai County',
        capacity: 24,
        ownerId: 'a0000000-0000-0000-0000-000000000001',
      );
      expect(created.code, 'BUS-03');
      expect((await service.getAllRoutes()).first.code, 'BUS-01');
      expect((await service.getStopsByBusCode('BUS-01')).first.stopCode, 'P-B01-01');

      final offlineBusService = BusService(
        supabaseClient: SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.anonKey,
          httpClient: MockClient((_) async => throw const SocketException('Connection refused', port: 54321)),
        ),
      );
      await expectLater(
        () => offlineBusService.createBus(
          code: 'BUS-99',
          plate: 'PNM-999',
          model: 'Toyota Coaster',
          capacity: 20,
          ownerId: 'a0000000-0000-0000-0000-000000000001',
        ),
        throwsA(isA<SocketException>()),
      );
    });

    test('OsrmRoutingService traza rutas viales en Penonomé y degrada offline sin coordenadas legacy', () async {
      final onlineOsrm = OsrmRoutingService(
        httpClient: MockClient((req) async {
          if (req.url.path.contains('/route/v1/driving/')) {
            return http.Response(
              jsonEncode({
                'code': 'Ok',
                'routes': [
                  {
                    'geometry': {
                      'coordinates': [
                        [-80.3572, 8.5186],
                        [-80.3551, 8.5112],
                      ],
                    },
                  },
                ],
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'code': 'Ok',
              'waypoints': [
                {
                  'name': 'Av. Héctor Conte Bermúdez',
                  'distance': 14.5,
                  'location': [-80.3552, 8.5115],
                },
              ],
            }),
            200,
          );
        }),
      );

      final route = await onlineOsrm.getDrivingRoute(const [
        LatLng(8.5186, -80.3572),
        LatLng(8.5112, -80.3551),
      ]);
      expect(route.length, 2);

      final street = await onlineOsrm.getNearestStreetInfo(const LatLng(8.5114, -80.3551));
      expect(street?.streetName, 'Av. Héctor Conte Bermúdez');

      final offlineOsrm = OsrmRoutingService(
        httpClient: MockClient((_) async => throw const SocketException('OSRM offline')),
      );
      final fallbackRoute = await offlineOsrm.getDrivingRoute(const [
        AppConstants.penonomeCenter,
        AppConstants.defaultSchoolPoint,
      ]);
      expect(fallbackRoute.length, greaterThanOrEqualTo(2));
      for (final p in fallbackRoute) {
        expect(p.latitude, inInclusiveRange(8.45, 8.60));
        expect(p.longitude, inInclusiveRange(-80.45, -80.25));
      }
      expect(fallbackRoute.any((p) => (p.latitude - 9.928).abs() < 0.2), isFalse);
    });

    test('BusService.extractCoveredSchools soporta múltiples colegios distintos por autobús', () {
      final students = [
        StudentPassengerMock(
          id: 1,
          name: 'Mateo',
          parentName: 'Carlos',
          parentPhone: '6000-0001',
          schoolName: 'Colegio Ángel María Herrera',
          pickupAddress: 'Centro',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 1,
          status: PassengerStatus.waiting,
        ),
        StudentPassengerMock(
          id: 2,
          name: 'Sofía',
          parentName: 'Elena',
          parentPhone: '6000-0002',
          schoolName: 'Colegio San Agustín',
          pickupAddress: 'Miraflores',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 2,
          status: PassengerStatus.waiting,
        ),
        StudentPassengerMock(
          id: 3,
          name: 'Lucas',
          parentName: 'Andrés',
          parentPhone: '6000-0003',
          schoolName: 'Colegio Ángel María Herrera',
          pickupAddress: 'Sonadora',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 3,
          status: PassengerStatus.waiting,
        ),
      ];

      final schools = BusService.extractCoveredSchools(
        students,
        fallbackSchool: 'Múltiples colegios',
      );
      expect(schools, [
        'Colegio Ángel María Herrera',
        'Colegio San Agustín',
      ]);

      final emptyFallback = BusService.extractCoveredSchools(
        const [],
        fallbackSchool: 'Múltiples colegios',
      );
      expect(emptyFallback, isEmpty);
    });

    test('RouteOptimizerService y BusTelemetryController avanzan en polilínea Dijkstra y recalculan con nuevos alumnos', () async {
      final offlineOsrm = OsrmRoutingService(
        httpClient: MockClient((_) async => throw const SocketException('OSRM offline')),
      );
      final optimizer = RouteOptimizerService(osrmService: offlineOsrm);
      final bus = BusMock(
        id: 1,
        code: 'BUS-01',
        plate: 'TBX-492',
        model: 'Toyota Coaster',
        capacity: 16,
        seatsOccupied: 1,
        status: 'En recorrido',
        driverName: 'Carlos Gómez',
        ownerName: 'Fernando Gómez',
        simulatedGpsActive: true,
        latitude: 8.5186,
        longitude: -80.3572,
      );

      final initialStudents = [
        StudentPassengerMock(
          id: 1,
          name: 'Mateo Gómez',
          parentName: 'Carlos',
          parentPhone: '6000-0001',
          schoolName: 'Colegio Ángel María Herrera',
          pickupAddress: 'Centro',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 1,
          status: PassengerStatus.waiting,
          pickupLatitude: 8.5242,
          pickupLongitude: -80.3522,
        ),
        StudentPassengerMock(
          id: 2,
          name: 'Ausente Hoy',
          parentName: 'Padre',
          parentPhone: '6000-0002',
          schoolName: 'Colegio San Agustín',
          pickupAddress: 'El Chorro',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 2,
          status: PassengerStatus.absent,
          pickupLatitude: 8.5210,
          pickupLongitude: -80.3540,
        ),
      ];

      final route1 = await optimizer.buildOptimalRoute(bus: bus, students: initialStudents);
      expect(route1.orderedActiveStudents.length, 1);
      expect(route1.orderedSchools.map((s) => s.name), ['Colegio Ángel María Herrera']);
      expect(route1.polylinePoints.length, greaterThanOrEqualTo(4));

      final telemetry = BusTelemetryController();
      addTearDown(telemetry.dispose);
      telemetry.updateRoute(route1, preserveProgress: false);
      telemetry.stepSimulation();

      expect(telemetry.currentSpeedKmH, inInclusiveRange(30.0, 45.0));
      expect(telemetry.distanceTraveledMeters, greaterThan(0.0));

      // Agregar un estudiante nuevo de otro colegio mientras el bus ya avanzó
      final updatedStudents = [
        ...initialStudents,
        StudentPassengerMock(
          id: 3,
          name: 'Lucía Nueva',
          parentName: 'Ana',
          parentPhone: '6000-0003',
          schoolName: 'Colegio San Agustín',
          pickupAddress: 'Miraflores',
          busCode: 'BUS-01',
          routeCode: 'BUS-01',
          order: 3,
          status: PassengerStatus.waiting,
          pickupLatitude: 8.5150,
          pickupLongitude: -80.3510,
        ),
      ];

      final route2 = await optimizer.buildOptimalRoute(bus: bus, students: updatedStudents);
      expect(route2.orderedActiveStudents.length, 2);
      expect(
        route2.orderedSchools.map((s) => s.name),
        containsAll(['Colegio Ángel María Herrera', 'Colegio San Agustín']),
      );

      telemetry.updateRoute(route2, preserveProgress: true);
      expect(telemetry.route?.orderedActiveStudents.length, 2);
      expect(telemetry.mode, TelemetryMode.simulated);
      telemetry.setMode(TelemetryMode.realGps);
      telemetry.pushRealGpsSample(const LatLng(8.5190, -80.3560), speedMetersPerSecond: 10.0);
      expect(telemetry.currentSpeedKmH, closeTo(36.0, 0.1));
    });
  });
}
