import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';

class EtaScreen extends StatelessWidget {
  final String routeCode;
  final String stopCode;

  const EtaScreen({
    super.key,
    required this.routeCode,
    required this.stopCode,
  });

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(routeCode);
    final stop = MockData.stops.where((s) => s.stopCode == stopCode).firstOrNull;
    final bus = MockData.getBusByCode(route?.busCode ?? "");

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('ETA simulado', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/routes');
            }
          },
        ),
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/eta',
        onNavigate: (route) => context.go(route),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SmartColors.smartBorder),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.directions_bus,
                size: 80,
                color: SmartColors.smartBlue.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 24),
            SmartRouteCard(
              child: Column(
                children: [
                  const Text('ETA estimado', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                  Text(
                    '${route?.etaMinutes ?? "--"} minutos',
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: SmartColors.smartBlue),
                  ),
                  const SizedBox(height: 8),
                  const StatusChip(text: 'Calculado'),
                  const SizedBox(height: 16),
                  const Divider(color: SmartColors.smartBorder),
                  const SizedBox(height: 16),
                  _DetailInfoRow(icon: Icons.map, label: 'Ruta', value: route?.name ?? 'N/A'),
                  _DetailInfoRow(icon: Icons.place, label: 'Parada', value: stop?.name ?? 'N/A'),
                  _DetailInfoRow(icon: Icons.straighten, label: 'Distancia simulada', value: routeCode == "R-BU" ? "1.2 km" : "2.5 km"),
                  _DetailInfoRow(icon: Icons.directions_bus, label: 'Bus asignado', value: bus?.code ?? 'N/A'),
                  _DetailInfoRow(icon: Icons.stacked_line_chart, label: 'Estado del bus', value: 'En camino'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            InfoBanner(
              text: 'El bus llegará aproximadamente en ${route?.etaMinutes ?? "--"} minutos.',
              icon: Icons.info,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Ver bus en mapa',
              icon: Icons.explore,
              onPressed: () => context.push('/map/$routeCode/$stopCode'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // Visual alert
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: SmartColors.smartBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_active, color: SmartColors.smartBlue),
                  SizedBox(width: 8),
                  Text('Actualizar ETA', style: TextStyle(color: SmartColors.smartBlue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: SmartColors.smartGray, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SmartColors.smartText)),
            ],
          ),
        ],
      ),
    );
  }
}
