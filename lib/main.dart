import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/auth/session_manager.dart';
import 'navigation/app_router.dart';
import 'ui/theme/theme.dart';

/// Punto de entrada principal de la aplicación SmartRoute.
void main() {
  runApp(
    // MultiProvider permite inyectar manejadores de estado (Providers) 
    // en toda la aplicación de manera global.
    MultiProvider(
      providers: [
        // SessionManager maneja el inicio de sesión y los datos del usuario activo.
        ChangeNotifierProvider(create: (_) => SessionManager()),
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
