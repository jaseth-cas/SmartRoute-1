import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/smart_route_card.dart';
import '../../../nucleo/widgets/session_info_card.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/info_banner.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final student = MockData.getPrimaryStudent();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: SmartColors.smartBlue),
            onPressed: () async {
              await context.push('/edit_profile');
              if (mounted) setState(() {});
            },
          ),
        ],
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
            Text(session?.name ?? student.parentName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
            Text(session?.email ?? 'padre.familia@smartroute.com', style: const TextStyle(fontSize: 14, color: SmartColors.smartGray)),
            const SizedBox(height: 24),
            SmartRouteCard(
              child: Column(
                children: [
                  _ProfileInfoItem(icon: Icons.badge, label: 'Rol', value: session?.role.displayName ?? 'Padre / Familia'),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _ProfileInfoItem(icon: Icons.child_care, label: 'Estudiante representado', value: student.name),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _ProfileInfoItem(icon: Icons.home_outlined, label: 'Dirección de recogida', value: student.pickupAddress),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _ProfileInfoItem(icon: Icons.phone, label: 'Teléfono de emergencia', value: student.parentPhone),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _ProfileInfoItem(icon: Icons.directions_bus, label: 'Unidad escolar asignada', value: student.busCode),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  _ProfileInfoItem(icon: Icons.place, label: 'Destino escolar', value: student.schoolName),
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
              text: 'Datos sincronizados con el perfil del estudiante y tutor en SmartRoute.',
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
