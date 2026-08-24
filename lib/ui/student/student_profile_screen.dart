import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/session_manager.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';
import '../components/session_info_card.dart';
import '../components/primary_button.dart';
import '../components/info_banner.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student_home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: SmartColors.smartLightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 60, color: SmartColors.smartBlue),
            ),
            const SizedBox(height: 16),
            Text(session?.name ?? 'Usuario', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
            Text(session?.email ?? 'correo@universidad.edu', style: const TextStyle(fontSize: 14, color: SmartColors.smartGray)),
            const SizedBox(height: 24),
            SmartRouteCard(
              child: Column(
                children: [
                  _ProfileInfoItem(icon: Icons.badge, label: 'Rol', value: session?.role.displayName ?? 'Estudiante'),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  const _ProfileInfoItem(icon: Icons.notifications, label: 'Notificaciones', value: 'Activas'),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  const _ProfileInfoItem(icon: Icons.map, label: 'Ruta favorita', value: 'Ruta Universidad → Boulevard'),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  const _ProfileInfoItem(icon: Icons.place, label: 'Parada favorita', value: 'Universidad'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SessionInfoCard(),
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
            const SizedBox(height: 24),
            const InfoBanner(
              text: 'Perfil simulado para fines de demostración académica.',
              icon: Icons.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SmartColors.smartBlue, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SmartColors.smartText)),
          ],
        ),
      ],
    );
  }
}
