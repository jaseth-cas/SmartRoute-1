import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/facial_boarding_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String routeStatus = "En recorrido";
  bool gpsActive = true;

  void _openFacialScanner() {
    FacialBoardingDialog.show(
      context,
      onBoardingCompleted: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final bus = MockData.getBusByCode('BUS-01') ?? MockData.buses.first;
    final passengers = MockData.getPassengersByBus('BUS-01');
    final absentCount = passengers.where((p) => p.status == PassengerStatus.absent).length;
    final onboardCount = passengers.where((p) => p.status == PassengerStatus.onboard).length;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/driver_home',
        onNavigate: (route) => context.go(route),
      ),
      appBar: AppBar(
        title: const Text('SmartRoute Conductor', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Terminal Facial AI',
            icon: const Icon(Icons.face_retouching_natural, color: SmartColors.smartBlue),
            onPressed: _openFacialScanner,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Perfil Conductor
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${session?.name ?? "Juan Pérez"}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                      ),
                      const Text('Ruta Escolar Activa • Conduce seguro', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sello Trust & Safety
            SmartRouteCard(
              color: SmartColors.smartLightGreen.withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: SmartColors.smartGreen, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Sello de Confianza SmartRoute', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartGreen)),
                        Text('Documentos, RTM y Antecedentes verificados para transporte escolar.', style: TextStyle(fontSize: 11, color: SmartColors.smartText)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alerta de Ausencias Reportadas (Ahorro de Ruta)
            if (absentCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Color(0xFFD97706), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('1 Ausencia Notificada Hoy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13)),
                          Text(
                            'Valentina Castro no asiste. La parada #4 se omitió automáticamente del GPS (-10 min).',
                            style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Información de Unidad y Recorrido
            SmartRouteCard(
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                      SizedBox(width: 12),
                      Text('Información de la Unidad Escolar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DriverDetailRow(icon: Icons.directions_bus, label: 'Unidad:', value: '${bus.code} (${bus.model})'),
                  _DriverDetailRow(icon: Icons.badge, label: 'Placa escolar:', value: bus.plate),
                  _DriverDetailRow(icon: Icons.alt_route, label: 'Ruta:', value: bus.routeName ?? 'Ruta Escolar Norte'),
                  _DriverDetailRow(icon: Icons.school, label: 'Colegio:', value: bus.schoolName ?? 'Colegio San José'),
                  _DriverDetailRow(icon: Icons.event_seat, label: 'Cupos asignados:', value: '${bus.seatsOccupied}/${bus.capacity} Asientos ocupados'),
                  _DriverDetailRow(icon: Icons.people, label: 'Alumnos a bordo ahora:', value: '$onboardCount niños'),
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
                          Text('GPS en tiempo real:', style: TextStyle(fontSize: 13, color: SmartColors.smartGray)),
                        ],
                      ),
                      StatusChip(text: gpsActive ? 'Activo' : 'Inactivo'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Botones de acción operativos
            ElevatedButton.icon(
              onPressed: _openFacialScanner,
              icon: const Icon(Icons.face, size: 22),
              label: const Text('Terminal Facial AI (Abordaje)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/driver_demand'),
              icon: const Icon(Icons.format_list_numbered, size: 20),
              label: const Text('Ver Manifiesto de Pasajeros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: SmartColors.smartBlue,
                side: const BorderSide(color: SmartColors.smartBlue),
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
                Text('Ubicación compartida con padres en vivo', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
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
                foregroundColor: SmartColors.smartRed,
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
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: SmartColors.smartGray, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: SmartColors.smartGray)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
        ],
      ),
    );
  }
}
