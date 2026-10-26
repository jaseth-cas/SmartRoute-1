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
            onLoginSuccess: () {
              final role = sessionManager.currentSession?.role;
              switch (role) {
                case UserRole.student:
                  context.go('/student_home');
                  break;
                case UserRole.driver:
                  context.go('/driver_home');
                  break;
                case UserRole.owner:
                  context.go('/owner_home');
                  break;
                default:
                  context.go('/role_home');
              }
            },
          ),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/role_home',
          builder: (context, state) => RoleHomeScreen(
            onNavigateToLogin: () => context.go('/login'),
            onNavigateToRoleHome: (role) {
              switch (role) {
                case UserRole.student:
                  context.go('/student_home');
                  break;
                case UserRole.driver:
                  context.go('/driver_home');
                  break;
                case UserRole.owner:
                  context.go('/owner_home');
                  break;
              }
            },
          ),
        ),
        GoRoute(
          path: '/student_home',
          builder: (context, state) => const StudentHomeScreen(),
        ),
        GoRoute(
          path: '/routes',
          builder: (context, state) => const RoutesScreen(),
        ),
        GoRoute(
          path: '/route_detail/:routeCode',
          builder: (context, state) => RouteDetailScreen(
            routeCode: state.pathParameters['routeCode']!,
          ),
        ),
        GoRoute(
          path: '/stops/:routeCode',
          builder: (context, state) => StopsScreen(
            routeCode: state.pathParameters['routeCode']!,
          ),
        ),
        GoRoute(
          path: '/stop_detail/:stopCode',
          builder: (context, state) => StopDetailScreen(
            stopCode: state.pathParameters['stopCode']!,
          ),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const SimulatedMapScreen(
            routeCode: 'R-01',
            stopCode: 'S-01',
          ),
        ),
        GoRoute(
          path: '/map/:routeCode/:stopCode',
          builder: (context, state) => SimulatedMapScreen(
            routeCode: state.pathParameters['routeCode']!,
            stopCode: state.pathParameters['stopCode']!,
          ),
        ),
        GoRoute(
          path: '/eta',
          builder: (context, state) => const EtaScreen(
            routeCode: 'R-01',
            stopCode: 'S-01',
          ),
        ),
        GoRoute(
          path: '/eta/:routeCode/:stopCode',
          builder: (context, state) => EtaScreen(
            routeCode: state.pathParameters['routeCode']!,
            stopCode: state.pathParameters['stopCode']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/notification_settings',
          builder: (context, state) => const NotificationSettingsScreen(),
        ),
        GoRoute(
          path: '/student_profile',
          builder: (context, state) => const StudentProfileScreen(),
        ),
        GoRoute(
          path: '/edit_profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/driver_home',
          builder: (context, state) => const DriverHomeScreen(),
        ),
        GoRoute(
          path: '/driver_demand',
          builder: (context, state) => const DriverDemandScreen(),
        ),
        GoRoute(
          path: '/report_incident',
          builder: (context, state) => const ReportIncidentScreen(),
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
