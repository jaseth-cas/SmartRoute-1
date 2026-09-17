import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';

class ManageBusesScreen extends StatelessWidget {
  const ManageBusesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Gestión de autobuses simulados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin_home');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Administra los autobuses registrados del sistema.',
              style: TextStyle(fontSize: 12, color: SmartColors.smartGray),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: MockData.buses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _ManageBusItemImproved(bus: MockData.buses[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageBusItemImproved extends StatelessWidget {
  final BusMock bus;

  const _ManageBusItemImproved({required this.bus});

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_bus, color: SmartColors.smartBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(bus.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SmartColors.smartText)),
                        const SizedBox(width: 8),
                        _BusStatusBadge(status: bus.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text('Placa: ', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text(bus.plate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        const Text('Modelo: ', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text(bus.model, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _BusActionInfo(icon: Icons.person, label: 'Conductor:', value: bus.driverName),
              const SizedBox(height: 8),
              _BusActionInfo(icon: Icons.business, label: 'Transportista:', value: bus.ownerName),
              const SizedBox(height: 8),
              _BusActionInfo(icon: Icons.alt_route, label: 'Ruta:', value: bus.routeName ?? 'No asignada'),
              const SizedBox(height: 8),
              _BusActionInfo(
                icon: Icons.settings_input_antenna,
                label: 'GPS simulado:',
                value: bus.simulatedGpsActive ? 'En línea' : 'Fuera de línea',
                valueColor: bus.simulatedGpsActive ? SmartColors.smartGreen : SmartColors.smartGray,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusActionInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _BusActionInfo({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = SmartColors.smartText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SmartColors.smartGray, size: 14),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

class _BusStatusBadge extends StatelessWidget {
  final String status;

  const _BusStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isOnline = status == "En recorrido" || status == "Activo" || status == "En servicio";
    final color = isOnline ? SmartColors.smartGreen : SmartColors.smartGray;
    final bgColor = isOnline ? SmartColors.smartLightGreen : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
