import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/colors.dart';
import 'smart_route_card.dart';
import 'status_chip.dart';

class RouteCard extends StatelessWidget {
  final RouteMock route;
  final VoidCallback onDetailClick;
  final VoidCallback onStopsClick;

  const RouteCard({
    super.key,
    required this.route,
    required this.onDetailClick,
    required this.onStopsClick,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map, color: SmartColors.smartBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: SmartColors.smartText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (route.isFavorite) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
                        ],
                      ],
                    ),
                    Text(
                      '${route.origin} → ${route.destination}',
                      style: const TextStyle(fontSize: 12, color: SmartColors.smartGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              StatusChip(text: route.status),
              if (route.status == 'Activa' && route.etaMinutes != null)
                StatusChip(text: 'ETA: ${route.etaMinutes} min')
              else if (route.status == 'Inactiva')
                const StatusChip(text: 'Fuera de servicio'),
            ],
          ),
          if (route.busCode != null) ...[
            const SizedBox(height: 8),
            Text(
              'Bus asignado: ${route.busCode}',
              style: const TextStyle(
                fontSize: 11,
                color: SmartColors.smartBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetailClick,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: SmartColors.smartBorder),
                  ),
                  child: const Text('Ver detalle', style: TextStyle(fontSize: 12, color: SmartColors.smartBlue)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onStopsClick,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartColors.smartLightBlue,
                    foregroundColor: SmartColors.smartBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Ver paradas', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
