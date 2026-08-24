import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/session_manager.dart';
import '../../data/mock/mock_data.dart';
import '../theme/colors.dart';
import '../components/student_bottom_bar.dart';
import '../components/session_info_card.dart';
import '../components/section_title.dart';
import '../components/smart_route_card.dart';
import '../components/status_chip.dart';
import '../components/info_banner.dart';
import '../components/primary_button.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = MockData.getDefaultStudentRoute();
    final defaultStop = MockData.getDefaultStudentStop();

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: Row(
          children: [
            const FlutterLogo(size: 32),
            const SizedBox(width: 8),
            const Text(
              'SmartRoute',
              style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Badge(
              child: Icon(Icons.notifications_none, color: SmartColors.smartText),
            ),
            onPressed: () => context.go('/notifications'),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/student_home',
        onNavigate: (route) => context.go(route),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: SmartColors.smartBlue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${session?.name ?? "Invitado"} 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: SmartColors.smartText,
                      ),
                    ),
                    const Text(
                      'Consulta el estado de tus rutas universitarias',
                      style: TextStyle(fontSize: 12, color: SmartColors.smartGray),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SessionInfoCard(),
            const SizedBox(height: 24),
            const SectionTitle(text: 'Ruta sugerida'),
            GestureDetector(
              onTap: () => context.go('/route_detail/${defaultRoute.code}'),
              child: SmartRouteCard(
                color: const Color(0xFFF0F7FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      defaultRoute.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SmartColors.smartText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Próximo bus', style: TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                            Text(
                              defaultRoute.busCode ?? "N/A",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ETA', style: TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                            Text(
                              '${defaultRoute.etaMinutes} minutos',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const StatusChip(text: 'En camino'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle(text: 'Parada favorita'),
            GestureDetector(
              onTap: () => context.go('/stop_detail/${defaultStop.stopCode}'),
              child: SmartRouteCard(
                child: Row(
                  children: [
                    const Icon(Icons.place, color: SmartColors.smartBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(defaultStop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('ID: ${defaultStop.stopCode}', style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                        ],
                      ),
                    ),
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const InfoBanner(text: 'Los datos son simulados. El sentido de la ruta puede cambiar las paradas.'),
            const SizedBox(height: 16),
            const SectionTitle(text: 'Accesos rápidos'),
            Row(
              children: [
                Expanded(
                  child: QuickAccessItem(
                    title: 'Rutas',
                    icon: Icons.map,
                    onClick: () => context.go('/routes'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: QuickAccessItem(
                    title: 'Paradas',
                    icon: Icons.place,
                    onClick: () => context.go('/stops/R-UB'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: QuickAccessItem(
                    title: 'Mapa',
                    icon: Icons.explore,
                    onClick: () => context.go('/map/${defaultRoute.code}/${defaultStop.stopCode}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: QuickAccessItem(
                    title: 'ETA',
                    icon: Icons.timer,
                    onClick: () => context.go('/eta/${defaultRoute.code}/${defaultStop.stopCode}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Cerrar sesión',
              icon: Icons.logout,
              backgroundColor: SmartColors.smartLightRed,
              foregroundColor: SmartColors.smartRed,
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class QuickAccessItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClick;

  const QuickAccessItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: SmartRouteCard(
        child: Column(
          children: [
            Icon(icon, color: SmartColors.smartBlue, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartText),
            ),
          ],
        ),
      ),
    );
  }
}
