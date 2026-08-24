import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';
import '../components/status_chip.dart';
import '../components/empty_state.dart';
import '../components/section_title.dart';
import '../components/primary_button.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeCode;

  const RouteDetailScreen({
    super.key,
    required this.routeCode,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    final route = MockData.getRouteByCode(widget.routeCode);
    isFavorite = route?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(widget.routeCode);

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Detalle de ruta', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (route != null)
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
      body: route == null
          ? const EmptyState(message: 'Ruta no encontrada')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmartRouteCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                        ),
                        const SizedBox(height: 4),
                        Text('Código: ${route.code}', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            StatusChip(text: route.status),
                            StatusChip(text: 'Sentido: ${route.direction.name.toUpperCase()}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _DetailInfoRow(icon: Icons.trip_origin, label: 'Origen', value: route.origin),
                        _DetailInfoRow(icon: Icons.location_on, label: 'Destino', value: route.destination),
                        _DetailInfoRow(icon: Icons.directions_bus, label: 'Bus asignado', value: route.busCode ?? "No asignado"),
                        _DetailInfoRow(icon: Icons.person, label: 'Conductor', value: route.busCode == "BUS-01" ? "Carlos Pérez" : "Luis Gómez"),
                        _DetailInfoRow(icon: Icons.timer, label: 'ETA aproximado', value: route.etaMinutes != null ? "${route.etaMinutes} min" : "N/A"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle(text: 'Descripción'),
                  SmartRouteCard(
                    child: Text(
                      route.description,
                      style: const TextStyle(fontSize: 14, color: SmartColors.smartText, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionTitle(text: 'Estadísticas simuladas'),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricMiniCard(
                          icon: Icons.list,
                          value: MockData.getStopsByRouteCode(route.code).length.toString(),
                          label: 'Paradas',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MetricMiniCard(
                          icon: Icons.straighten,
                          value: route.code == "R-BU" ? "4.5 km" : "9.0 km",
                          label: 'Distancia',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: 'Ver paradas',
                    icon: Icons.format_list_numbered,
                    onPressed: () => context.go('/stops/${route.code}'),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    text: 'Ver bus en mapa',
                    icon: Icons.map,
                    backgroundColor: SmartColors.smartLightBlue,
                    foregroundColor: SmartColors.smartBlue,
                    onPressed: () {
                      final stopCode = MockData.getStopsByRouteCode(route.code).firstOrNull?.stopCode ?? "P-BU-001";
                      context.go('/map/${route.code}/$stopCode');
                    },
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

class _MetricMiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricMiniCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        children: [
          Icon(icon, color: SmartColors.smartBlue, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 10, color: SmartColors.smartGray)),
        ],
      ),
    );
  }
}
