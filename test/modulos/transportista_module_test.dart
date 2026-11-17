import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/owner_home_screen.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/owner_map_screen.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/register_bus_screen.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';

class _NoRealtimeStudentService extends StudentService {
  _NoRealtimeStudentService({super.supabaseClient});

  @override
  RealtimeChannel? subscribeToStudentChanges({
    required String channelName,
    required VoidCallback onChanged,
  }) =>
      null;
}

class _NoRealtimeAttendanceService extends AttendanceService {
  _NoRealtimeAttendanceService({super.supabaseClient});

  @override
  Stream<List<Map<String, dynamic>>> streamTodayAttendance() =>
      const Stream.empty();
}

class _NoRealtimeBusService extends BusService {
  _NoRealtimeBusService({super.supabaseClient});

  @override
  Stream<List<BusMock>> streamAllBuses() => const Stream.empty();
}

http.Response _jsonResp(http.Request req, Object? data, {int status = 200}) {
  return http.Response(
    data is String ? data : jsonEncode(data),
    status,
    headers: const {'content-type': 'application/json'},
    request: req,
  );
}

Future<void> _initTestBindings() async {
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
  setUpAll(_initTestBindings);

  group('Módulo Transportista (Dueño de Flota) - Flota, Cupos y Sello de Confianza', () {
    testWidgets('RegisterBusScreen registra bus con dueno_id y maneja conflictos 409 y red 54321', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      String mode = 'conflict';
      bool busCreated = false;

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {
              'id': 'b0000000-0000-0000-0000-000000000002',
              'nombre': 'Carlos Andrés Gómez',
              'email': 'conductor@smartroute.com',
              'telefono': '+507 6412-3344',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/autobuses' && req.method == 'POST') {
          if (mode == 'conflict') {
            return _jsonResp(
              req,
              {'code': '23505', 'message': 'duplicate key value violates unique constraint'},
              status: 409,
            );
          }
          if (mode == 'socket') {
            throw const SocketException('Connection refused', port: 54321);
          }
          busCreated = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          expect(body['codigo'], 'BUS-03');
          expect(body['placa'], 'PNM-303');
          expect(body['dueno_id'], 'a0000000-0000-0000-0000-000000000001');
          return _jsonResp(req, {'id': 3, ...body}, status: 201);
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
        initialLocation: '/register_bus',
        routes: [
          GoRoute(path: '/register_bus', builder: (_, _) => const RegisterBusScreen()),
          GoRoute(path: '/owner_home', builder: (_, _) => const Scaffold(body: Text('OWNER HOME OK'))),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.owner)),
            Provider(create: (_) => AuthService(supabaseClient: supabase, httpClient: mockHttp)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.enterText(find.widgetWithText(TextFormField, 'Ej. BUS-03'), 'BUS-03');
      await tester.enterText(find.widgetWithText(TextFormField, 'Ej. SJ-884210'), 'PNM-303');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ej. Mercedes-Benz Sprinter 516'),
        'Hyundai County',
      );

      final submitBtn = find.text('REGISTRAR AUTOBÚS EN FLOTA');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        find.text('Conflicto: ya existe un autobús con ese código o placa en la base de datos.'),
        findsOneWidget,
      );
      ScaffoldMessenger.of(tester.element(find.byType(RegisterBusScreen))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 100));

      mode = 'socket';
      await tester.tap(submitBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.textContaining('Sin conexión con Supabase (127.0.0.1:54321)'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(RegisterBusScreen))).clearSnackBars();
      await tester.pump(const Duration(milliseconds: 100));

      mode = 'ok';
      await tester.tap(submitBtn);
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(busCreated, isTrue);
      expect(find.text('OWNER HOME OK'), findsOneWidget);
    });

    testWidgets('OwnerHomeScreen omite pasarela de pago, muestra flota y asigna cupo buscable', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool assignedInDb = false;

      final mockHttp = MockClient((req) async {
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
              'dueno_id': 'a0000000-0000-0000-0000-000000000001',
              'conductor_id': 'b0000000-0000-0000-0000-000000000002',
              'colegio_asignado': 'Colegio Ángel María Herrera',
              'is_verified': true,
            },
            {
              'id': 2,
              'codigo': 'BUS-02',
              'placa': 'SKL-810',
              'modelo': 'Nissan Civilian',
              'capacidad': 20,
              'asientos_ocupados': 4,
              'estado': 'Disponible',
              'dueno_id': 'a0000000-0000-0000-0000-000000000001',
              'conductor_id': 'b0000000-0000-0000-0000-000000000005',
              'colegio_asignado': 'Colegio San Agustín',
              'is_verified': true,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {
              'id': 'a0000000-0000-0000-0000-000000000001',
              'nombre': 'Don Fernando Gómez',
              'email': 'dueno@smartroute.com',
              'telefono': '+507 6200-1111',
            },
            {
              'id': 'c0000000-0000-0000-0000-000000000099',
              'nombre': 'Jaseth Castillo',
              'email': 'jaseth@smartroute.com',
              'telefono': '+507 6900-1234',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'GET') {
          return _jsonResp(req, [
            {
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
              'latitud_recogida': 8.5284,
              'longitud_recogida': -80.3582,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros' && req.method == 'POST') {
          assignedInDb = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(
            req,
            {
              'id': 15,
              ...body,
              'latitud_recogida': 8.5186,
              'longitud_recogida': -80.3572,
            },
            status: 201,
          );
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
        initialLocation: '/owner_home',
        routes: [
          GoRoute(path: '/owner_home', builder: (_, _) => const OwnerHomeScreen()),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.owner)),
            Provider(create: (_) => AuthService(supabaseClient: supabase, httpClient: mockHttp)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider<StudentService>(
              create: (_) => _NoRealtimeStudentService(supabaseClient: supabase),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Pasarela de pago / cobros comentada temporalmente
      expect(find.text('INGRESOS'), findsNothing);
      expect(find.text('CONTROL DE CUOTAS Y MENSUALIDADES'), findsNothing);
      expect(find.text('PASAJEROS Y ASIGNACIÓN DE CUPOS'), findsOneWidget);
      expect(find.text('2 ACTIVAS'), findsOneWidget);

      final assignQuotaBtn = find.text('ASIGNAR CUPO');
      await tester.ensureVisible(assignQuotaBtn);
      await tester.tap(assignQuotaBtn);
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Buscar y Seleccionar Estudiante'),
        'jase',
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Jaseth Castillo').last);
      await tester.pump(const Duration(milliseconds: 100));

      final mapCheckbox = find.byType(CheckboxListTile);
      if (mapCheckbox.evaluate().isNotEmpty) {
        final checkboxWidget = tester.widget<CheckboxListTile>(mapCheckbox);
        if (checkboxWidget.value == true) {
          await tester.tap(mapCheckbox);
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      await tester.enterText(find.widgetWithText(TextFormField, 'Dirección de Recogida'), 'Penonomé Centro');
      await tester.tap(find.text('ASIGNAR ASIENTO'));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(assignedInDb, isTrue);
      expect(find.textContaining('asignado a BUS-01'), findsOneWidget);
    });

    testWidgets('TrustSafetyDialog muestra el Sello de Confianza y requisitos legales del transportista', (tester) async {
      final bus = BusMock(
        id: 1,
        code: 'BUS-01',
        plate: 'TBX-492',
        model: 'Toyota Coaster Escolar',
        capacity: 16,
        seatsOccupied: 4,
        status: 'En recorrido',
        driverName: 'Carlos Gómez',
        ownerName: 'Don Fernando Gómez',
        simulatedGpsActive: true,
        isVerified: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<BusService>(create: (_) => BusService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => TrustSafetyDialog.show(context, bus: bus, isOwnerView: true),
                  child: const Text('Abrir Sello'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Sello'));
      await tester.pumpAndSettle();

      expect(find.text('Sello de Confianza Escolar'), findsOneWidget);
      expect(find.text('CERTIFICADO'), findsOneWidget);
      expect(find.text('Récord Policivo y Antecedentes Penales'), findsOneWidget);
      expect(find.text('Licencia Comercial de Conducción'), findsOneWidget);
      expect(find.text('Póliza de Seguros Todo Riesgo Escolar'), findsOneWidget);
      expect(find.text('Revisión Técnico-Mecánica (RTM)'), findsOneWidget);
      expect(find.text('Suspender Sello de Confianza'), findsOneWidget);
    });

    testWidgets('OwnerMapScreen soporta colores por bus, filtro multi-selección y múltiples colegios offline', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/autobuses') {
          return _jsonResp(req, [
            {
              'id': 1,
              'codigo': 'BUS-01',
              'placa': 'TBX-492',
              'modelo': 'Toyota Coaster',
              'capacidad': 16,
              'asientos_ocupados': 2,
              'estado': 'En recorrido',
              'latitud_actual': 8.5186,
              'longitud_actual': -80.3572,
              'velocidad_kmh': 35,
            },
            {
              'id': 2,
              'codigo': 'BUS-02',
              'placa': 'SKL-810',
              'modelo': 'Nissan Civilian',
              'capacidad': 20,
              'asientos_ocupados': 1,
              'estado': 'Disponible',
              'latitud_actual': 8.5220,
              'longitud_actual': -80.3550,
              'velocidad_kmh': 0,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, [
            {
              'id': 1,
              'nombre': 'Mateo Gómez',
              'padre_nombre': 'Carlos',
              'padre_telefono': '6000-0001',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Centro',
              'autobus_codigo': 'BUS-01',
              'orden': 1,
              'latitud_recogida': 8.5242,
              'longitud_recogida': -80.3522,
            },
            {
              'id': 2,
              'nombre': 'Sofía Ramírez',
              'padre_nombre': 'Elena',
              'padre_telefono': '6000-0002',
              'colegio': 'Colegio San Agustín',
              'direccion_recogida': 'Miraflores',
              'autobus_codigo': 'BUS-01',
              'orden': 2,
              'latitud_recogida': 8.5150,
              'longitud_recogida': -80.3510,
            },
            {
              'id': 3,
              'nombre': 'Lucía Torres',
              'padre_nombre': 'Ana',
              'padre_telefono': '6000-0003',
              'colegio': 'I.P.T. Leonila Pinzón de Grimaldo',
              'direccion_recogida': 'Sonadora',
              'autobus_codigo': 'BUS-02',
              'orden': 1,
              'latitud_recogida': 8.5260,
              'longitud_recogida': -80.3490,
            },
          ]);
        }
        return _jsonResp(req, []);
      });

      final supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.anonKey,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: mockHttp,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.owner)),
            Provider<BusService>(create: (_) => _NoRealtimeBusService(supabaseClient: supabase)),
            Provider<StudentService>(create: (_) => _NoRealtimeStudentService(supabaseClient: supabase)),
            Provider<AttendanceService>(create: (_) => _NoRealtimeAttendanceService(supabaseClient: supabase)),
          ],
          child: const MaterialApp(home: OwnerMapScreen()),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Inicialmente ambos buses y todos los estudiantes están visibles
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('2 UNIDADES VISIBLES'), findsOneWidget);
      expect(find.text('Mateo'), findsOneWidget);
      expect(find.text('Lucía'), findsOneWidget);

      // Tocar chip BUS-01 aísla BUS-01 y oculta el pin de Lucía (BUS-02)
      await tester.tap(find.byKey(const Key('bus_filter_chip_BUS-01')));
      await tester.pump();
      expect(find.text('Mateo'), findsOneWidget);
      expect(find.text('Lucía'), findsNothing);
      expect(find.textContaining('Colegio Ángel María Herrera'), findsOneWidget);
      expect(find.textContaining('Colegio San Agustín'), findsOneWidget);
      expect(find.text('SIMULAR'), findsOneWidget);

      // Tocar chip BUS-02 agrega BUS-02 en multi-selección
      await tester.tap(find.byKey(const Key('bus_filter_chip_BUS-02')));
      await tester.pump();
      expect(find.text('2 UNIDADES VISIBLES'), findsOneWidget);
      expect(find.text('Mateo'), findsOneWidget);
      expect(find.text('Lucía'), findsOneWidget);

      // Tocar "Todos" cuando ambos están activos limpia la selección
      await tester.tap(find.byKey(const Key('bus_filter_all')));
      await tester.pump();
      expect(find.text('0 UNIDADES VISIBLES'), findsOneWidget);
      expect(find.text('Mateo'), findsNothing);
      expect(find.text('Lucía'), findsNothing);
    });
  });
}
