import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/navegacion/app_router.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/incident_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/tema/theme.dart';

/// Punto de entrada principal de la aplicación SmartRoute.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la conexión con el servidor local de Supabase (Docker)
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Aviso: Inicialización de Supabase: $e');
  }

  runApp(
    // MultiProvider permite inyectar manejadores de estado (Providers) y servicios
    // en toda la aplicación de manera global.
    MultiProvider(
      providers: [
        // SessionManager maneja el inicio de sesión y los datos del usuario activo.
        ChangeNotifierProvider(create: (_) => SessionManager()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => BusService()),
        Provider(create: (_) => StudentService()),
        Provider(create: (_) => AttendanceService()),
        Provider(create: (_) => IncidentService()),
      ],
      child: const SmartRouteApp(),
    ),
  );
}

/// Widget principal de la aplicación.
class SmartRouteApp extends StatelessWidget {
  const SmartRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lee el estado de la sesión actual
    final sessionManager = context.read<SessionManager>();
    // Configura el enrutador con las reglas de autenticación
    final router = AppRouter.createRouter(sessionManager);

    return MaterialApp.router(
      title: 'SmartRoute',
      // Aplica el tema claro global (definido en theme.dart)
      theme: SmartTheme.lightTheme,
      routerConfig: router,
      // Oculta la etiqueta de "DEBUG" en la esquina superior derecha
      debugShowCheckedModeBanner: false,
    );
  }
}
