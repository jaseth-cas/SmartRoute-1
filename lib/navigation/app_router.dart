import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth/session_manager.dart';
import '../data/models/models.dart';
import '../ui/splash/splash_screen.dart';
import '../ui/login/login_screen.dart';
import '../ui/auth/role_home_screen.dart';
import '../ui/student/student_home_screen.dart';
import '../ui/student/routes_screen.dart';
import '../ui/student/route_detail_screen.dart';
import '../ui/student/stops_screen.dart';
import '../ui/student/stop_detail_screen.dart';
import '../ui/student/simulated_map_screen.dart';
import '../ui/student/eta_screen.dart';
import '../ui/student/notifications_screen.dart';
import '../ui/student/notification_settings_screen.dart';
import '../ui/student/student_profile_screen.dart';
import '../ui/admin/admin_home_screen.dart';
import '../ui/admin/manage_routes_screen.dart';
import '../ui/admin/manage_buses_screen.dart';
import '../ui/admin/manage_stops_screen.dart';
import '../ui/admin/assign_stops_screen.dart';
import '../ui/driver/driver_home_screen.dart';
import '../ui/driver/driver_demand_screen.dart';
import '../ui/owner/owner_home_screen.dart';
import '../ui/owner/owner_map_screen.dart';
import '../ui/owner/register_bus_screen.dart';

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
