import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String routeStatus = "En recorrido";
  bool gpsActive = true;

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('SmartRoute Conductor', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: SmartColors.smartGray),
            onPressed: () {
              // Alerts
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: SmartColors.smartBlue, size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${session?.name ?? "Conductor"}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                    ),
                    const Text('¡Buen día! Conduce seguro.', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SmartRouteCard(
              color: SmartColors.smartLightBlue.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: SmartColors.smartBlue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Text('Rol actual: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            Text('DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
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
            SmartRouteCard(
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                      SizedBox(width: 12),
                      Text('Información del recorrido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DriverDetailRow(icon: Icons.directions_bus, label: 'Bus asignado:', value: 'BUS-01'),
                  _DriverDetailRow(icon: Icons.badge, label: 'Placa:', value: '123456'),
                  _DriverDetailRow(icon: Icons.alt_route, label: 'Ruta asignada:', value: 'Ruta Universidad - Centro'),
                  const SizedBox(height: 8),
                  const Divider(color: SmartColors.smartBorder, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.stacked_line_chart, color: SmartColors.smartGray, size: 16),
                          SizedBox(width: 12),
                          Text('Estado del recorrido:', style: TextStyle(fontSize: 13, color: SmartColors.smartGray)),
                        ],
                      ),
                      StatusChip(text: routeStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.location_on, color: SmartColors.smartGray, size: 16),
                          SizedBox(width: 12),
                          Text('GPS simulado:', style: TextStyle(fontSize: 13, color: SmartColors.smartGray)),
                        ],
                      ),
                      StatusChip(text: gpsActive ? 'Activo' : 'Inactivo'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/driver_demand'),
              icon: const Icon(Icons.map),
              label: const Text('Ver mapa de demanda', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartDarkBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  gpsActive = !gpsActive;
                });
              },
              icon: const Icon(Icons.settings_input_antenna),
              label: Text(gpsActive ? 'Desactivar GPS simulado' : 'Activar GPS simulado', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  routeStatus = "Finalizado";
                  gpsActive = false;
                });
              },
              icon: const Icon(Icons.flag),
              label: const Text('Finalizar ruta', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartGray,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.push('/report_incident'),
              icon: const Icon(Icons.warning_rounded, size: 18),
              label: const Text('Reportar un Incidente', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SmartColors.smartRed,
                side: const BorderSide(color: SmartColors.smartRed),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.update, color: SmartColors.smartGray, size: 14),
                SizedBox(width: 8),
                Text('Última ubicación simulada: Hace 1 minuto', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SmartColors.smartBlue,
                side: const BorderSide(color: SmartColors.smartBorder),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DriverDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DriverDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: SmartColors.smartGray, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: SmartColors.smartGray)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
        ],
      ),
    );
  }
}
