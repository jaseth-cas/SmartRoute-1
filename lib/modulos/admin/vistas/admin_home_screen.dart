import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('SmartRoute Admin', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role_home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: SmartColors.smartRed),
            onPressed: () {
              sessionManager.logout();
              context.go('/login');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: SmartColors.smartBlue),
            onPressed: () {
              // Simulated alerts
            },
          ),
        ],
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
                    const Text('Bienvenido,', style: TextStyle(fontSize: 14, color: SmartColors.smartGray)),
                    Text(
                      session?.name ?? "Admin",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                    ),
                    const Text('Aquí tienes un resumen general del sistema.', style: TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.group,
                    value: '12',
                    label: 'Usuarios\nRegistrados',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.map,
                    value: '2',
                    label: 'Rutas\nActivas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.directions_bus,
                    value: '2',
                    label: 'Autobuses\nen Flota',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.satellite_alt,
                    value: '1',
                    label: 'GPS\nActivos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Acciones de Gestión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SmartColors.smartBorder),
              ),
              child: Column(
                children: [
                  _AdminNavOption(
                    title: 'Gestionar rutas',
                    icon: Icons.map,
                    onClick: () => context.push('/manage_routes'),
                  ),
                  const Divider(height: 1, color: SmartColors.smartBorder),
                  _AdminNavOption(
                    title: 'Gestionar paradas',
                    icon: Icons.place,
                    onClick: () => context.push('/manage_stops'),
                  ),
                  const Divider(height: 1, color: SmartColors.smartBorder),
                  _AdminNavOption(
                    title: 'Gestionar autobuses',
                    icon: Icons.directions_bus,
                    onClick: () => context.push('/manage_buses'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _AdminMetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SmartColors.smartLightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: SmartColors.smartBlue, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: SmartColors.smartText)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AdminNavOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClick;

  const _AdminNavOption({
    required this.title,
    required this.icon,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SmartColors.smartLightBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: SmartColors.smartBlue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: SmartColors.smartText)),
            ),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
