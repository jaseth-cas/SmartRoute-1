import 'dart:async';
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
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_card_sorting_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_demand_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_dijkstra_routing_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/facial_checkin_screen.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/incident_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

http.Response _jsonResp(http.Request req, Object? data, {int status = 200}) {
  return http.Response(
    data is String ? data : jsonEncode(data),
    status,
    headers: const {'content-type': 'application/json'},
    request: req,
  );
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeDartHttpClient();
}

class _FakeDartHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeHttpClientRequest();
  @override
  void close({bool force = false}) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  bool bufferOutput = false;
  @override
  int contentLength = -1;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = false;
  @override
  Encoding encoding = utf8;

  @override
  void add(List<int> data) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async => stream.drain<void>();
  @override
  Future<void> flush() async {}
  @override
  Future<HttpClientResponse> get done async => _FakeHttpClientResponse();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  String? value(String name) => null;
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _transparentPng = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ];

  @override
  int get statusCode => 200;
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  int get contentLength => _transparentPng.length;
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoRealtimeStudentService extends StudentService {
  _NoRealtimeStudentService({required super.supabaseClient});

  @override
  RealtimeChannel? subscribeToStudentChanges({
    required String channelName,
    required VoidCallback onChanged,
  }) =>
      null;

  @override
  Future<void> unsubscribeChannel(RealtimeChannel? channel) async {}
}

class _NoRealtimeAttendanceService extends AttendanceService {
  _NoRealtimeAttendanceService({required super.supabaseClient});

  @override
  Stream<List<Map<String, dynamic>>> streamTodayAttendance() =>
      const Stream<List<Map<String, dynamic>>>.empty();
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

  group('Módulo Conductor - Card Sorting, Manifiesto, Dijkstra, Check-in e Incidentes', () {
    testWidgets('DriverCardSortingScreen separa ausentes, ordena por cercanía y lanza Dijkstra', (tester) async {
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
              'asientos_ocupados': 3,
              'estado': 'En recorrido',
              'conductor_id': 'b0000000-0000-0000-0000-000000000002',
              'latitud_actual': 8.5186,
              'longitud_actual': -80.3572,
              'colegio_asignado': 'Colegio Ángel María Herrera',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {'id': 'b0000000-0000-0000-0000-000000000002', 'nombre': 'Carlos Gómez'},
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, [
            {
              'id': 1,
              'nombre': 'Mateo Gómez',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Vía Sonadora',
              'autobus_codigo': 'BUS-01',
              'orden': 1,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
              'latitud_recogida': 8.5350,
              'longitud_recogida': -80.3700,
            },
            {
              'id': 2,
              'nombre': 'Sofía Ramírez',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Parque 8 de Diciembre',
              'autobus_codigo': 'BUS-01',
              'orden': 2,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
              'latitud_recogida': 8.5190,
              'longitud_recogida': -80.3575,
            },
            {
              'id': 3,
              'nombre': 'Lucas Ausente',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'El Chorro',
              'autobus_codigo': 'BUS-01',
              'orden': 3,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
              'latitud_recogida': 8.5210,
              'longitud_recogida': -80.3540,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/asistencia_diaria') {
          return _jsonResp(req, [
            {'estudiante_id': 3, 'estado': 'absent'},
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

      List<StudentStopCardItem>? routedStops;
      final router = GoRouter(
        initialLocation: '/cards',
        routes: [
          GoRoute(path: '/cards', builder: (_, _) => const DriverCardSortingScreen()),
          GoRoute(
            path: '/driver_dijkstra_routing',
            builder: (_, state) {
              routedStops = state.extra as List<StudentStopCardItem>?;
              return const Scaffold(body: Text('DIJKSTRA SCREEN OK'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.driver)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider<StudentService>(create: (_) => _NoRealtimeStudentService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('2 PARADAS ACTIVAS'), findsOneWidget);
      await tester.tap(find.text('POR CERCANÍA'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('auto-ordenadas'), findsOneWidget);

      await tester.tap(find.text('Confirmar y Generar Ruta'));
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('DIJKSTRA SCREEN OK'), findsOneWidget);
      expect(routedStops?.length, 2);
      expect(routedStops!.first.name, 'Sofía Ramírez');
    });

    testWidgets('DriverDemandScreen muestra EmptyState sin bus y filtra manifiesto al asignar unidad', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      bool returnBus = false;
      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/autobuses') {
          if (!returnBus) return _jsonResp(req, []);
          return _jsonResp(req, [
            {
              'id': 1,
              'codigo': 'BUS-01',
              'placa': 'TBX-492',
              'modelo': 'Toyota Coaster',
              'capacidad': 16,
              'asientos_ocupados': 2,
              'estado': 'En recorrido',
              'conductor_id': 'b0000000-0000-0000-0000-000000000002',
              'nombre_ruta': 'Ruta Norte Penonomé',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {'id': 'b0000000-0000-0000-0000-000000000002', 'nombre': 'Carlos Gómez'},
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, [
            {
              'id': 1,
              'nombre': 'Mateo A Bordo',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Vía Sonadora',
              'autobus_codigo': 'BUS-01',
              'orden': 1,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
            },
            {
              'id': 2,
              'nombre': 'Sofía Ausente',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Miraflores',
              'autobus_codigo': 'BUS-01',
              'orden': 2,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/asistencia_diaria') {
          return _jsonResp(req, [
            {'estudiante_id': 1, 'estado': 'onboard'},
            {'estudiante_id': 2, 'estado': 'absent'},
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

      final router = GoRouter(
        initialLocation: '/driver_demand',
        routes: [
          GoRoute(path: '/driver_demand', builder: (_, _) => const DriverDemandScreen()),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.driver)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider<StudentService>(create: (_) => _NoRealtimeStudentService(supabaseClient: supabase)),
            Provider<AttendanceService>(create: (_) => _NoRealtimeAttendanceService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Sin autobús asignado'), findsOneWidget);

      returnBus = true;
      await tester.tap(find.text('REINTENTAR'));
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('2/16 CUPOS'), findsOneWidget);
      await tester.tap(find.text('A BORDO').last);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Mateo A Bordo'), findsOneWidget);
      expect(find.text('Sofía Ausente'), findsNothing);
    });

    testWidgets('DriverDijkstraRoutingScreen omite ausentes y completa ruta óptima hacia Penonomé', (tester) async {
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
              'conductor_id': 'b0000000-0000-0000-0000-000000000002',
              'latitud_actual': 8.5186,
              'longitud_actual': -80.3572,
              'colegio_asignado': 'Colegio Ángel María Herrera',
            },
          ]);
        }
        if (req.url.path == '/rest/v1/perfiles') {
          return _jsonResp(req, [
            {'id': 'b0000000-0000-0000-0000-000000000002', 'nombre': 'Carlos Gómez'},
          ]);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, [
            {
              'id': 1,
              'nombre': 'Mateo Presente',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'Vía Sonadora',
              'autobus_codigo': 'BUS-01',
              'orden': 1,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
              'latitud_recogida': 8.5284,
              'longitud_recogida': -80.3582,
            },
            {
              'id': 2,
              'nombre': 'Ausente Omitido',
              'padre_nombre': 'Carlos Gómez',
              'padre_telefono': '+507 6300-4567',
              'colegio': 'Colegio Ángel María Herrera',
              'direccion_recogida': 'El Chorro',
              'autobus_codigo': 'BUS-01',
              'orden': 2,
              'cuota_mensual': 65.0,
              'estado_pago': 'Al día',
              'latitud_recogida': 8.5210,
              'longitud_recogida': -80.3540,
            },
          ]);
        }
        if (req.url.path == '/rest/v1/asistencia_diaria') {
          return _jsonResp(req, [
            {'estudiante_id': 2, 'estado': 'absent'},
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

      final router = GoRouter(
        initialLocation: '/dijkstra',
        routes: [
          GoRoute(path: '/dijkstra', builder: (_, _) => const DriverDijkstraRoutingScreen()),
          GoRoute(path: '/driver_home', builder: (_, _) => const Scaffold(body: Text('DRIVER HOME OK'))),
        ],
      );

      final prevOverrides = HttpOverrides.current;
      HttpOverrides.global = _TestHttpOverrides();
      addTearDown(() => HttpOverrides.global = prevOverrides);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.driver)),
            Provider(create: (_) => BusService(supabaseClient: supabase)),
            Provider<StudentService>(create: (_) => _NoRealtimeStudentService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(find.textContaining('Mateo Presente'), findsWidgets);
      expect(find.textContaining('Ausente Omitido'), findsNothing);

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 1100));
      }
      expect(find.text('DRIVER HOME OK'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('FacialCheckinScreen carga estudiante objetivo y regresa a cabina', (tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, {
            'id': 1,
            'nombre': 'Mateo Gómez',
            'padre_nombre': 'Carlos Gómez',
            'padre_telefono': '+507 6300-4567',
            'colegio': 'Colegio Ángel María Herrera',
            'direccion_recogida': 'Vía Sonadora',
            'autobus_codigo': 'BUS-01',
            'orden': 1,
            'cuota_mensual': 65.0,
            'estado_pago': 'Al día',
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

      final router = GoRouter(
        initialLocation: '/facial',
        routes: [
          GoRoute(path: '/facial', builder: (_, _) => const FacialCheckinScreen(studentId: 1)),
          GoRoute(path: '/driver_home', builder: (_, _) => const Scaffold(body: Text('CABINA CONDUCTOR OK'))),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SessionManager()..login(UserRole.driver)),
            Provider<StudentService>(create: (_) => _NoRealtimeStudentService(supabaseClient: supabase)),
            Provider<AttendanceService>(create: (_) => _NoRealtimeAttendanceService(supabaseClient: supabase)),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('TERMINAL FACIAL AI // ABORDAJE'), findsOneWidget);
      final cancelBtn = find.text('CANCELAR // REGRESAR A CABINA');
      await tester.ensureVisible(cancelBtn);
      await tester.pump();
      await tester.tap(cancelBtn);
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('CABINA CONDUCTOR OK'), findsOneWidget);
    });

    test('AttendanceService e IncidentService registran abordajes, ahorro e incidentes en ruta', () async {
      final states = <String>[];
      bool incidentInserted = false;

      final mockClient = MockClient((req) async {
        if (req.url.path == '/rest/v1/asistencia_diaria' && req.method == 'POST') {
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          states.add(body['estado'].toString());
          return _jsonResp(req, [body], status: 201);
        }
        if (req.url.path == '/rest/v1/estudiantes_pasajeros') {
          return _jsonResp(req, {
            'nombre': 'Mateo Gómez',
            'autobus_codigo': 'BUS-01',
            'colegio': 'Colegio Ángel María Herrera',
          });
        }
        if (req.url.path == '/rest/v1/incidentes_ruta' && req.method == 'POST') {
          incidentInserted = true;
          return _jsonResp(req, [jsonDecode(req.body)], status: 201);
        }
        if (req.url.path == '/rest/v1/notificaciones' && req.method == 'POST') {
          return _jsonResp(req, [jsonDecode(req.body)], status: 201);
        }
        return _jsonResp(req, []);
      });

      final supabase = SupabaseClient(
        SupabaseConfig.supabaseUrl,
        SupabaseConfig.anonKey,
        httpClient: mockClient,
      );

      final attendance = AttendanceService(supabaseClient: supabase);
      await attendance.checkInPassenger(studentId: 1);
      await attendance.checkOutPassenger(studentId: 1);
      await attendance.reportAbsence(studentId: 1, isAbsent: true);
      expect(states, ['onboard', 'delivered', 'absent']);

      final incidents = IncidentService(supabaseClient: supabase);
      expect(incidents.resolveNotificationType('Mecánico'), 'alert');
      expect(incidents.resolveNotificationType('Tráfico'), 'info');
      await incidents.reportIncident(
        busCode: 'BUS-01',
        title: 'Falla menor',
        description: 'Cambio de llanta',
        incidentType: 'Mecánico',
      );
      expect(incidentInserted, isTrue);
    });
  });
}
