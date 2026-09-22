import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/session_info_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = MockData.getDefaultStudentRoute();
    final defaultStop = MockData.getDefaultStudentStop();

    return PopScope(
      canPop: false, // Previene que el botón atrás de Android cierre la app
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo2.png', width: 28, height: 28, fit: BoxFit.contain),
            const SizedBox(width: 8),
            const Text(
              'SmartRoute',
              style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: SmartColors.smartBlue),
            onPressed: () => context.push('/student_profile'), // Añadido botón a Perfil/Logout
          ),
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
            const SectionTitle(text: 'Próximo Bus (ETA)'),
            GestureDetector(
              onTap: () {
                if (defaultRoute != null) {
                  context.push('/route_detail/${defaultRoute.code}');
                }
              },
              child: SmartRouteCard(
                color: const Color(0xFFF0F7FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          defaultRoute?.name ?? 'No hay ruta',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SmartColors.smartText),
                        ),
                        const Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${defaultRoute?.etaMinutes ?? 0}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: SmartColors.smartBlue),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MIN',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: SmartColors.smartGray),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Parada: ${defaultStop?.name ?? "N/A"}', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        const StatusChip(text: 'En camino'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SectionTitle(text: 'Rastreo en Vivo'),
                Text('Ver mapa completo', style: TextStyle(fontSize: 12, color: SmartColors.smartBlue, fontWeight: FontWeight.bold)),
              ],
            ),
            GestureDetector(
              onTap: () {
                if (defaultRoute != null && defaultStop != null) {
                  context.push('/map/${defaultRoute.code}/${defaultStop.stopCode}');
                }
              },
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SmartColors.smartBorder),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 40, color: SmartColors.smartBlue),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: SmartColors.smartBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Abrir Mapa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const InfoBanner(text: 'Los datos mostrados son simulados en esta versión.'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}
