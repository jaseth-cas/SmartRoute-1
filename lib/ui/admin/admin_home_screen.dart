import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth/session_manager.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';

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
            icon: const Icon(Icons.notifications_none),
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
            SmartRouteCard(
              color: SmartColors.smartLightBlue.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.security, color: SmartColors.smartBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Rol actual: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
                          ],
                        ),
                        Text('JWT simulado: ${sessionManager.currentToken ?? "N/A"}', style: const TextStyle(fontSize: 10, color: SmartColors.smartGray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.group,
                    value: '12',
                    label: 'Usuarios registrados',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.map,
                    value: '2',
                    label: 'Rutas activas',
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
                    label: 'Autobuses registrados',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AdminMetricCard(
                    icon: Icons.settings_input_antenna,
                    value: '1',
                    label: 'GPS simulados activos',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AdminNavOption(
              title: 'Gestionar rutas',
              subtitle: 'Crear, editar y eliminar rutas',
              icon: Icons.map,
              onClick: () => context.push('/manage_routes'),
            ),
            _AdminNavOption(
              title: 'Gestionar paradas',
              subtitle: 'Administrar paradas del sistema',
              icon: Icons.place,
              onClick: () => context.push('/manage_stops'),
            ),
            _AdminNavOption(
              title: 'Gestionar autobuses',
              subtitle: 'Administrar autobuses registrados',
              icon: Icons.directions_bus,
              onClick: () => context.push('/manage_buses'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock, size: 18),
                  SizedBox(width: 12),
                  Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
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
  final String subtitle;
  final IconData icon;
  final VoidCallback onClick;

  const _AdminNavOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: InkWell(
        onTap: onClick,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: SmartColors.smartBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SmartColors.smartText)),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
