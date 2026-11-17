import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/edit_profile_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/student_location_picker_screen.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/widgets/school_selector_field.dart';

http.Response _jsonResp(http.Request req, Object? data, {int status = 200}) {
  return http.Response(
    data is String ? data : jsonEncode(data),
    status,
    headers: const {'content-type': 'application/json'},
    request: req,
  );
}

Future<void> _ensureSupabaseInitialized() async {
  GoogleFonts.config.allowRuntimeFetching = false;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') return <String, Object>{};
      return true;
    },
  );
  try {
    Supabase.instance;
  } catch (_) {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
      httpClient: MockClient((req) async => _jsonResp(req, [])),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureSupabaseInitialized);

  group('Módulo Padre - Perfil, Selector GPS y StudentService', () {
    testWidgets('EditProfileScreen precarga por GET y persiste cambios reales por PUT', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool profileUpdated = false;
      bool studentUpdated = false;

      final studentRow = {
        'id': 1,
        'nombre': 'Mateo Gómez',
        'padre_nombre': 'Carlos Gómez',
        'padre_telefono': '+507 6300-4567',
        'padre_id': 'c0000000-0000-0000-0000-000000000003',
        'colegio': 'Colegio Ángel María Herrera',
        'direccion_recogida': 'Vía Sonadora Norte',
        'autobus_codigo': 'BUS-01',
        'orden': 1,
        'cuota_mensual': 65.0,
        'estado_pago': 'Al día',
        'latitud_recogida': 8.5284,
        'longitud_recogida': -80.3582,
      };

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'GET') {
          if (req.url.queryParameters['id'] == 'eq.1') {
            return _jsonResp(req, studentRow);
          }
          return _jsonResp(req, [studentRow]);
        }
        if (req.url.path == '/rest/v1/perfiles' && req.method == 'GET') {
          return _jsonResp(req, {
            'id': 'c0000000-0000-0000-0000-000000000003',
            'nombre': 'Carlos Gómez',
            'email': 'padre1@smartroute.com',
            'telefono': '+507 6300-4567',
          });
        }
        if (req.url.path == '/rest/v1/perfiles' && req.method == 'PATCH') {
          profileUpdated = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(req, [body]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'PATCH') {
          studentUpdated = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(req, {...studentRow, ...body});
        }
        return _jsonResp(req, []);
      });

      final supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: mockHttp,
      );

      final router = GoRouter(
        initialLocation: '/edit_profile',
        routes: [
          GoRoute(path: '/edit_profile', builder: (_, _) => const EditProfileScreen()),
          GoRoute(path: '/student_profile', builder: (_, _) => const Scaffold(body: Text('PERFIL PADRE OK'))),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.student)),
            Provider(create: (_) => AuthService(supabaseClient: supabase, httpClient: mockHttp)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider(create: (_) => StudentService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Carlos Gómez'), findsOneWidget);
      expect(find.text('Mateo Gómez'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Carlos Gómez'), 'Carlos Gómez Actualizado');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Vía Sonadora Norte'),
        'Residencial El Chorro, Casa 8',
      );

      final saveButton = find.text('GUARDAR CAMBIOS');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      for (int i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(profileUpdated, isTrue);
      expect(studentUpdated, isTrue);
      expect(find.text('PERFIL PADRE OK'), findsOneWidget);
    });

    testWidgets('EditProfileScreen informa error explícito si falla 127.0.0.1:54321', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'GET') {
          return _jsonResp(req, [
            {
              'id': 1,
              'nombre': 'Mateo Gómez',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'padre_id': 'c0000000-0000-0000-0000-000000000003',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Vía Sonadora Norte',
              'autobus_codigo': 'BUS-01',
              'orden': 1,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles' && req.method == 'GET') {
          return _jsonResp(req, {
            'id': 'c0000000-0000-0000-0000-000000000003',
            'nombre': 'Carlos Gómez',
            'email': 'padre1@smartroute.com',
            'telefono': '+507 6300-4567',
          });
        }
        if (req.method == 'PATCH' && req.url.path == '/rest/v1/perfiles') {
          throw const SocketException('Connection refused', port: 54321);
        }
        return _jsonResp(req, []);
      });

      final supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: mockHttp,
      );

      final router = GoRouter(
        initialLocation: '/edit_profile',
        routes: [
          GoRoute(path: '/edit_profile', builder: (_, _) => const EditProfileScreen()),
          GoRoute(path: '/student_profile', builder: (_, _) => const Scaffold(body: Text('PERFIL'))),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.student)),
            Provider(create: (_) => AuthService(supabaseClient: supabase, httpClient: mockHttp)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider(create: (_) => StudentService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final saveButton = find.text('GUARDAR CAMBIOS');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.textContaining('Sin conexión con Supabase (127.0.0.1:54321)'), findsOneWidget);
    });

    testWidgets('StudentLocationPickerScreen valida coordenadas DD/DMS, guarda PUT y emite stream', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool locationPersisted = false;
      final student = StudentPassengerMock(
        id: 1,
        name: 'Mateo Gómez',
        parentName: 'Carlos Gómez',
        parentPhone: '+507 6300-4567',
        parentId: 'c0000000-0000-0000-0000-000000000003',
        schoolName: 'Colegio Ángel María Herrera',
        pickupAddress: 'Vía Sonadora',
        busCode: 'BUS-01',
        routeCode: 'BUS-01',
        order: 1,
        status: PassengerStatus.waiting,
        monthlyFee: 65,
        paymentStatus: 'Al día',
        pickupLatitude: 8.5186,
        pickupLongitude: -80.3572,
      );

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'GET') {
          final row = {
            'id': 1,
            'nombre': 'Mateo Gómez',
            'padre_nombre': 'Carlos Gómez',
            'padre_telefono': '+507 6300-4567',
            'padre_id': 'c0000000-0000-0000-0000-000000000003',
            'colegio': 'Colegio Ángel María Herrera',
            'direccion_recogida': 'Vía Sonadora',
            'autobus_codigo': 'BUS-01',
            'orden': 1,
            'cuota_mensual': 65.0,
            'estado_pago': 'Al día',
            'latitud_recogida': 8.5186,
            'longitud_recogida': -80.3572,
          };
          if (req.url.queryParameters['id'] == 'eq.1') {
            return _jsonResp(req, row);
          }
          return _jsonResp(req, [row]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'PATCH') {
          locationPersisted = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(req, {
            'id': 1,
            'nombre': 'Mateo Gómez',
            'padre_nombre': 'Carlos Gómez',
            'padre_telefono': '+507 6300-4567',
            'padre_id': 'c0000000-0000-0000-0000-000000000003',
            'colegio': 'Colegio Ángel María Herrera',
            'direccion_recogida': body['direccion_recogida'] ?? 'Avenida Central Penonomé',
            'autobus_codigo': 'BUS-01',
            'orden': 1,
            'cuota_mensual': 65.0,
            'estado_pago': 'Al día',
            'latitud_recogida': body['latitud_recogida'],
            'longitud_recogida': body['longitud_recogida'],
          });
        }
        return _jsonResp(req, []);
      });

      final supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: mockHttp,
      );

      final osrmMockClient = MockClient((req) async {
        if (req.url.path.contains('/nearest/')) {
          return _jsonResp(req, {
            'code': 'Ok',
            'waypoints': [
              {
                'name': 'Avenida Central Penonomé',
                'distance': 12.0,
                'location': [-80.35, 8.516667],
              },
            ],
          });
        }
        return _jsonResp(req, {
          'code': 'Ok',
          'routes': [
            {
              'geometry': {
                'coordinates': [
                  [-80.35, 8.516667],
                  [-80.3568, 8.5194],
                ],
              },
            },
          ],
        });
      });

      final emitted = <StudentPassengerMock>[];
      final sub = StudentService.locationUpdatesStream.listen(emitted.add);
      addTearDown(() {
        sub.cancel();
        osrmMockClient.close();
        mockHttp.close();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.student)),
            Provider(create: (_) => StudentService(supabaseClient: supabase)),
          ],
          child: MaterialApp(
            home: StudentLocationPickerScreen(
              student: student,
              initialCoordinates: const LatLng(8.5186, -80.3572),
              initialAddress: 'Vía Sonadora',
              osrmService: OsrmRoutingService(httpClient: osrmMockClient),
              enableMap: false,
            ),
          ),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final coordField = find.widgetWithText(TextField, 'Coordenadas (DD, DMM o DMS)');
      await tester.enterText(coordField, '95.0000, -80.3500');
      await tester.tap(find.text('BUSCAR EN EL MAPA'));
      await tester.pump();
      expect(find.textContaining('Latitud fuera de rango'), findsOneWidget);

      await tester.enterText(coordField, '8°31\'00"N 80°21\'00"W');
      await tester.tap(find.text('BUSCAR EN EL MAPA'));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Latitud fuera de rango'), findsNothing);
      expect(find.textContaining('Avenida Central Penonomé'), findsOneWidget);

      final confirmBtn = find.text('CONFIRMAR Y GUARDAR UBICACIÓN');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 5));

      expect(locationPersisted, isTrue);
      expect(emitted.any((e) => e.id == 1 && (e.pickupLatitude ?? 0) > 8.51 && (e.pickupLatitude ?? 0) < 8.52), isTrue);
    });

    test('StudentService no emite actualización en stream si falla PATCH en 54321', () async {
      final failingHttp = MockClient((req) async {
        if (req.method == 'GET') {
          return _jsonResp(req, {'id': 1, 'autobus_codigo': 'BUS-01'});
        }
        throw const SocketException('Connection refused', port: 54321);
      });

      final service = StudentService(
        supabaseClient: SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.anonKey,
          httpClient: failingHttp,
        ),
      );

      final emitted = <StudentPassengerMock>[];
      final sub = StudentService.locationUpdatesStream.listen(emitted.add);

      await expectLater(
        () => service.updateStudent(studentId: 1, pickupAddress: 'Penonomé Centro'),
        throwsA(isA<SocketException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();
      expect(emitted, isEmpty);
    });

    testWidgets('SchoolSelectorField abre diálogo buscable sin overflow con teclado virtual y soporta Otro', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String selected = 'Colegio Ángel María Herrera';

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              viewInsets: EdgeInsets.only(bottom: 260),
            ),
            child: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SchoolSelectorField(
                  initialValue: selected,
                  onChanged: (val) => selected = val,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Colegio Ángel María Herrera'));
      await tester.pumpAndSettle();

      expect(find.text('SELECCIONAR COLEGIO'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Filtrar por un colegio inexistente para verificar búsqueda y mostrar la opción comodín
      await tester.enterText(find.byType(TextField).last, 'Escuela Nueva');
      await tester.pumpAndSettle();

      expect(find.text('Otro (especificar colegio)'), findsOneWidget);
      await tester.tap(find.text('Otro (especificar colegio)'));
      await tester.pumpAndSettle();

      expect(find.text('Nombre del colegio personalizado'), findsOneWidget);
      expect(selected, 'Escuela Nueva');
      expect(tester.takeException(), isNull);
    });
  });
}
