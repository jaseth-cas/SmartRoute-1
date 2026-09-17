import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/modulos/splash/vistas/splash_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/login_screen.dart';
import 'package:smartroute_flutter/modulos/autenticacion/vistas/role_home_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/student_home_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/routes_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/route_detail_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/stops_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/stop_detail_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/simulated_map_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/eta_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/notifications_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/notification_settings_screen.dart';
import 'package:smartroute_flutter/modulos/estudiante/vistas/student_profile_screen.dart';
import 'package:smartroute_flutter/modulos/admin/vistas/admin_home_screen.dart';
import 'package:smartroute_flutter/modulos/admin/vistas/manage_routes_screen.dart';
import 'package:smartroute_flutter/modulos/admin/vistas/manage_buses_screen.dart';
import 'package:smartroute_flutter/modulos/admin/vistas/manage_stops_screen.dart';
import 'package:smartroute_flutter/modulos/admin/vistas/assign_stops_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_home_screen.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_demand_screen.dart';
import 'package:smartroute_flutter/modulos/propietario/vistas/owner_home_screen.dart';
import 'package:smartroute_flutter/modulos/propietario/vistas/owner_map_screen.dart';
import 'package:smartroute_flutter/modulos/propietario/vistas/register_bus_screen.dart';

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
            onStartClick: () => context.go('/login'),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(
            onLoginSuccess: () => context.go('/role_home'),
          ),
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
                case UserRole.admin:
                  context.go('/admin_home');
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
          path: '/admin_home',
          builder: (context, state) => const AdminHomeScreen(),
        ),
        GoRoute(
          path: '/manage_routes',
          builder: (context, state) => const ManageRoutesScreen(),
        ),
        GoRoute(
          path: '/manage_buses',
          builder: (context, state) => const ManageBusesScreen(),
        ),
        GoRoute(
          path: '/manage_stops',
          builder: (context, state) => const ManageStopsScreen(),
        ),
        GoRoute(
          path: '/assign_stops/:routeCode',
          builder: (context, state) => AssignStopsScreen(
            routeCode: state.pathParameters['routeCode']!,
          ),
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
      // Lógica de redirección (Protección de rutas)
      redirect: (context, state) {
        final isLoggedIn = sessionManager.isLoggedIn;
        final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/splash';
        
        if (!isLoggedIn && !isGoingToAuth) {
          // Si intenta acceder a una pantalla sin estar logueado, se envía al login
          return '/login';
        }
        return null; // Permitir el acceso
      },
    );
  }
}
