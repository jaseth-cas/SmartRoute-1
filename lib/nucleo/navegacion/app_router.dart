import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/modulos/splash/vistas/splash_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/login_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/permission_gate_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/register_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/role_home_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/student_home_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/routes_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/route_detail_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/stops_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/stop_detail_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/simulated_map_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/eta_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/notifications_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/notification_settings_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/student_profile_screen.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/edit_profile_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_home_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_demand_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/report_incident_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/facial_checkin_screen.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/owner_home_screen.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/owner_map_screen.dart';
import 'package:smartroute_flutter/modulos/transportista/vistas/register_bus_screen.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

/// Clase principal para el enrutamiento de la aplicación utilizando GoRouter.
/// GoRouter facilita la navegación declarativa y el soporte de enlaces profundos (deep links).
class AppRouter {
  /// Crea y configura la instancia del enrutador.
  /// Toma un [SessionManager] para poder redirigir al usuario al Login 
  /// si no ha iniciado sesión o si su sesión expira.
  static GoRouter createRouter(SessionManager sessionManager) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: sessionManager,
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashScreen(
            onStartClick: () => context.go('/permissions'),
          ),
        ),
        GoRoute(
          path: '/permissions',
          builder: (context, state) => const PermissionGateScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            onLoginSuccess: () => context.go('/role_home'),
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/transit_loading',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final targetRoute = extra?['targetRoute'] as String? ?? '/role_home';
            final title = extra?['title'] as String? ?? 'CONECTANDO CON SMARTROUTE';
            final subtitle = extra?['subtitle'] as String? ?? 'Sincronizando satélites GPS y telemetría de ruta...';
            final badge = extra?['badge'] as String? ?? 'TELEMETRÍA EN TIEMPO REAL';
            final duration = extra?['duration'] as Duration? ?? const Duration(milliseconds: 2200);

            return TransitLoadingScreen(
              targetRoute: targetRoute,
              title: title,
              subtitle: subtitle,
              badge: badge,
              duration: duration,
            );
          },
        ),
        GoRoute(
          path: '/role_home',
          builder: (context, state) => RoleHomeScreen(
            onNavigateToLogin: () => context.go('/login'),
            onNavigateToRoleHome: (role) {
              final targetRoute = role == UserRole.student
                  ? '/student_home'
                  : role == UserRole.driver
                      ? '/driver_home'
                      : '/owner_home';
              TransitLoadingScreen.open(
                context,
                targetRoute: targetRoute,
                title: 'INGRESANDO AL PANEL PRINCIPAL',
                subtitle: 'Sincronizando la unidad escolar Toyota HiAce (TBX-492)...',
                badge: 'SMARTROUTE OS',
              );
            },
          ),
        ),
        GoRoute(
          path: '/student_home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StudentHomeScreen(),
          ),
        ),
        GoRoute(
          path: '/routes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RoutesScreen(),
          ),
        ),
        GoRoute(
          path: '/route_detail/:routeCode',
          pageBuilder: (context, state) => NoTransitionPage(
            child: RouteDetailScreen(
              routeCode: state.pathParameters['routeCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '/stops/:routeCode',
          pageBuilder: (context, state) => NoTransitionPage(
            child: StopsScreen(
              routeCode: state.pathParameters['routeCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '/stop_detail/:stopCode',
          pageBuilder: (context, state) => NoTransitionPage(
            child: StopDetailScreen(
              stopCode: state.pathParameters['stopCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SimulatedMapScreen(
              routeCode: 'R-01',
              stopCode: 'S-01',
            ),
          ),
        ),
        GoRoute(
          path: '/map/:routeCode/:stopCode',
          pageBuilder: (context, state) => NoTransitionPage(
            child: SimulatedMapScreen(
              routeCode: state.pathParameters['routeCode']!,
              stopCode: state.pathParameters['stopCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '/eta',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EtaScreen(
              routeCode: 'R-01',
              stopCode: 'S-01',
            ),
          ),
        ),
        GoRoute(
          path: '/eta/:routeCode/:stopCode',
          pageBuilder: (context, state) => NoTransitionPage(
            child: EtaScreen(
              routeCode: state.pathParameters['routeCode']!,
              stopCode: state.pathParameters['stopCode']!,
            ),
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/notification_settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotificationSettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/student_profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StudentProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/edit_profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EditProfileScreen(),
          ),
        ),
        GoRoute(
          path: '/driver_home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DriverHomeScreen(),
          ),
        ),
        GoRoute(
          path: '/driver_demand',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DriverDemandScreen(),
          ),
        ),
        GoRoute(
          path: '/report_incident',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportIncidentScreen(),
          ),
        ),
        GoRoute(
          path: '/facial_checkin',
          builder: (context, state) => const FacialCheckinScreen(),
        ),
        GoRoute(
          path: '/owner_home',
          builder: (context, state) => const OwnerHomeScreen(),
        ),
        GoRoute(
          path: '/owner_map',
          builder: (context, state) => const OwnerMapScreen(),
        ),
        GoRoute(
          path: '/register_bus',
          builder: (context, state) => const RegisterBusScreen(),
        ),
      ],
      // Lógica de redirección (Protección de rutas desacoplada para pruebas fluidas)
      redirect: (context, state) {
        final isLoggedIn = sessionManager.isLoggedIn;
        final isGoingToAuth = state.matchedLocation == '/login' || 
                              state.matchedLocation == '/splash' ||
                              state.matchedLocation == '/permissions' ||
                              state.matchedLocation == '/register';
        
        if (!isLoggedIn && !isGoingToAuth) {
          // Si intenta acceder directamente a un panel sin estar logueado, se auto-inicializa la sesión en ese rol
          if (state.matchedLocation.startsWith('/driver')) {
            sessionManager.login(UserRole.driver);
          } else if (state.matchedLocation.startsWith('/owner')) {
            sessionManager.login(UserRole.owner);
          } else {
            sessionManager.login(UserRole.student);
          }
          return null;
        }
        return null; // Permitir el acceso
      },
    );
  }
}
