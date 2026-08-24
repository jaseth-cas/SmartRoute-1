import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/colors.dart';
import 'smart_route_card.dart';

class StopCard extends StatelessWidget {
  final StopMock stop;
  final VoidCallback onSelect;
  final VoidCallback onDetail;

  const StopCard({
    super.key,
    required this.stop,
    required this.onSelect,
    required this.onDetail,
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stop.order.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: SmartColors.smartBlue,
                    fontSize: 12,
                  ),
                ),
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
                            stop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: SmartColors.smartText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (stop.isFavorite) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.favorite, color: Colors.red, size: 14),
                        ],
                      ],
                    ),
                    Text(
                      'Código: ${stop.stopCode} | ${stop.distanceFromStartKm} km',
                      style: const TextStyle(fontSize: 11, color: SmartColors.smartGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 15,
                child: ElevatedButton(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartColors.smartBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Seleccionar', style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: const BorderSide(color: SmartColors.smartBorder),
                  ),
                  child: const Text('Detalle', style: TextStyle(fontSize: 11, color: SmartColors.smartBlue)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
