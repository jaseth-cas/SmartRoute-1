import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';

class StopDetailScreen extends StatefulWidget {
  final String stopCode;

  const StopDetailScreen({
    super.key,
    required this.stopCode,
  });

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    final stop = MockData.stops.where((s) => s.stopCode == widget.stopCode).firstOrNull;
    isFavorite = stop?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final stop = MockData.stops.where((s) => s.stopCode == widget.stopCode).firstOrNull;
    final route = stop != null ? MockData.getRouteByCode(stop.routeCode) : null;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Detalle de parada', style: TextStyle(fontWeight: FontWeight.bold)),
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
        actions: [
          if (stop != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : SmartColors.smartGray,
              ),
              onPressed: () {
                setState(() {
                  isFavorite = !isFavorite;
                });
              },
            ),
        ],
      ),
      body: stop == null
          ? const EmptyState(message: 'Parada no encontrada')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmartRouteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stop.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
                        Text('Código de parada: ${stop.stopCode}', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        const SizedBox(height: 16),
                        _DetailInfoRow(icon: Icons.info, label: 'Referencia', value: stop.reference),
                        _DetailInfoRow(icon: Icons.map, label: 'Ruta asociada', value: route?.name ?? 'N/A'),
                        _DetailInfoRow(icon: Icons.format_list_numbered, label: 'Orden en la ruta', value: stop.order.toString()),
                        _DetailInfoRow(icon: Icons.straighten, label: 'Distancia acumulada', value: '${stop.distanceFromStartKm} km'),
                        if (stop.latitude != null)
                          _DetailInfoRow(icon: Icons.location_on, label: 'Coordenadas', value: '${stop.latitude}, ${stop.longitude}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SmartRouteCard(
                    color: SmartColors.smartLightBlue.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        const Text('ETA simulado para esta parada', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        Text(
                          '${route?.etaMinutes ?? "--"} minutos',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: SmartColors.smartBlue),
                        ),
                        const StatusChip(text: 'Calculado'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Seleccionar parada',
                    icon: Icons.check,
                    onPressed: () => context.go('/map/${stop.routeCode}/${stop.stopCode}'),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Ver bus en mapa',
                    icon: Icons.explore,
                    backgroundColor: SmartColors.smartLightBlue,
                    foregroundColor: SmartColors.smartBlue,
                    onPressed: () => context.go('/map/${stop.routeCode}/${stop.stopCode}'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      // Toggle visual alert
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
                        Text('Activar alerta de proximidad', style: TextStyle(color: SmartColors.smartBlue, fontWeight: FontWeight.bold)),
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
