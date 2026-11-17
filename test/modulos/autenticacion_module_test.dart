import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/gps_permission_helper.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';

http.Response _jsonResp(http.Request req, Object? data, {int status = 200}) {
  return http.Response(
    data is String ? data : jsonEncode(data),
    status,
    headers: const {'content-type': 'application/json'},
    request: req,
  );
}

class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled;
  LocationPermission checkResult;
  LocationPermission requestResult = LocationPermission.whileInUse;
  bool appSettingsOpened = false;
  bool locationSettingsOpened = false;

  _FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.checkResult = LocationPermission.whileInUse,
  });

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => checkResult;

  @override
  Future<LocationPermission> requestPermission() async => requestResult;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened = true;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened = true;
    return true;
  }
}

void main() {
  group('Módulo Autenticación - Sesión, Roles, AuthService y Permisos GPS', () {
    late GeolocatorPlatform originalPlatform;

    setUp(() {
      originalPlatform = GeolocatorPlatform.instance;
    });

    tearDown(() {
      GeolocatorPlatform.instance = originalPlatform;
    });

    test('SessionManager gestiona login, conmutación de roles y logout', () {
      final manager = SessionManager();
      int notifications = 0;
      manager.addListener(() => notifications++);

      expect(manager.isLoggedIn, isTrue);
      expect(manager.currentSession?.email, 'padre1@smartroute.com');

      manager.logout();
      expect(manager.isLoggedIn, isFalse);

      manager.login(UserRole.student);
      expect(manager.currentSession!.userId, 'c0000000-0000-0000-0000-000000000003');
      expect(manager.currentSession!.email, 'padre1@smartroute.com');

      manager.switchRole(UserRole.driver);
      expect(manager.currentSession!.userId, 'b0000000-0000-0000-0000-000000000002');
      expect(manager.currentSession!.email, 'conductor@smartroute.com');

      manager.switchRole(UserRole.owner);
      expect(manager.currentSession!.userId, 'a0000000-0000-0000-0000-000000000001');
      expect(manager.currentSession!.email, 'dueno@smartroute.com');
      expect(notifications, 4);

      manager.loginWithSupabase(
        userId: 'b0000000-0000-0000-0000-000000000005',
        name: 'Luis Alberto Mendoza',
        email: 'conductor2@smartroute.com',
        role: UserRole.driver,
        token: 'real.jwt.token',
      );
      expect(manager.currentSession!.token, 'real.jwt.token');

      manager.updateUserInfo(name: 'Luis Mendoza');
      expect(manager.currentSession!.name, 'Luis Mendoza');
    });

    test('AuthService valida correos, registra conductores y propaga fallos de red', () async {
      bool signupCalled = false;
      bool profileUpserted = false;

      final mockHttp = MockClient((req) async {
        if (req.url.path == '/rest/v1/perfiles' && req.method == 'GET') {
          return _jsonResp(req, [
            {
              'id': 'b0000000-0000-0000-0000-000000000002',
              'nombre': 'Carlos Andrés Gómez',
              'email': 'conductor@smartroute.com',
              'telefono': '+507 6412-3344',
            },
            {
              'id': 'b0000000-0000-0000-0000-000000000005',
              'nombre': 'Luis Alberto Mendoza',
              'email': 'conductor2@smartroute.com',
              'telefono': '+507 6678-9012',
            },
          ]);
        }
        if (req.url.path == '/auth/v1/signup') {
          signupCalled = true;
          return _jsonResp(req, {
            'user': {'id': 'b0000000-0000-0000-0000-000000000009'},
          });
        }
        if (req.url.path == '/rest/v1/perfiles' && req.method == 'POST') {
          profileUpserted = true;
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return _jsonResp(req, [body], status: 201);
        }
        return _jsonResp(req, []);
      });

      final service = AuthService(
        supabaseClient: SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.anonKey,
          httpClient: mockHttp,
        ),
        httpClient: mockHttp,
      );

      await expectLater(() => service.resetPassword('correo_invalido'), throwsArgumentError);

      final drivers = await service.getAvailableDrivers();
      expect(drivers.length, 2);
      expect(drivers.first['email'], 'conductor@smartroute.com');

      final driver = await service.registerDriverProfile(
        nombre: 'Roberto Díaz',
        email: 'Conductor3@SmartRoute.com',
        telefono: '+507 6999-8888',
      );
      expect(signupCalled, isTrue);
      expect(profileUpserted, isTrue);
      expect(driver?['email'], 'conductor3@smartroute.com');

      final timeoutService = AuthService(
        supabaseClient: SupabaseClient(
          SupabaseConfig.supabaseUrl,
          SupabaseConfig.anonKey,
          httpClient: MockClient((_) async => throw TimeoutException('54321 timeout')),
        ),
      );
      await expectLater(
        () => timeoutService.updateUserProfile(
          userId: 'c0000000-0000-0000-0000-000000000003',
          nombre: 'Carlos Gómez',
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    testWidgets('GpsPermissionHelper solicita permisos y activa diálogo GPS en flujo post-login', (tester) async {
      final fake = _FakeGeolocatorPlatform(
        serviceEnabled: false,
        checkResult: LocationPermission.whileInUse,
      );
      GeolocatorPlatform.instance = fake;

      bool? ready;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  ready = await GpsPermissionHelper.ensureLocationReady(ctx);
                },
                child: const Text('Verificar GPS'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Verificar GPS'));
      await tester.pumpAndSettle();

      expect(find.text('GPS DEL DISPOSITIVO APAGADO'), findsOneWidget);
      await tester.tap(find.text('ACTIVAR GPS'));
      await tester.pumpAndSettle();
      expect(fake.locationSettingsOpened, isTrue);

      fake.serviceEnabled = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(ready, isTrue);

      fake.checkResult = LocationPermission.denied;
      fake.requestResult = LocationPermission.always;
      ready = null;
      await tester.tap(find.text('Verificar GPS'));
      await tester.pumpAndSettle();
      expect(ready, isTrue);

      fake.checkResult = LocationPermission.deniedForever;
      ready = null;
      await tester.tap(find.text('Verificar GPS'));
      await tester.pumpAndSettle();
      expect(find.text('PERMISO DE UBICACIÓN REQUERIDO'), findsOneWidget);
      await tester.tap(find.text('ABRIR AJUSTES'));
      await tester.pumpAndSettle();
      expect(fake.appSettingsOpened, isTrue);
      await tester.tap(find.text('MÁS TARDE'));
      await tester.pumpAndSettle();
      expect(ready, isFalse);
    });
  });
}
