import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';

class DriverDemandScreen extends StatelessWidget {
  const DriverDemandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stops = MockData.getStopsByRouteCode('R-UB'); // Simulando ruta actual

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Mapa de Demanda', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/driver_home');
            }
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            color: const Color(0xFFE2E8F0),
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/img.png',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text('Mapa simulado (Imagen no encontrada)', style: TextStyle(color: SmartColors.smartGray)),
                  ),
                ),
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                // LayoutBuilder para posicionar los heatmaps
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final maxHeight = constraints.maxHeight;

                    return Stack(
                      children: [
                        _HeatmapSpot(maxWidth: maxWidth, maxHeight: maxHeight, percentX: 0.89, percentY: 0.96, color: SmartColors.smartRed, size: 60),
                        _HeatmapSpot(maxWidth: maxWidth, maxHeight: maxHeight, percentX: 0.73, percentY: 0.42, color: SmartColors.smartYellow, size: 45),
                        _HeatmapSpot(maxWidth: maxWidth, maxHeight: maxHeight, percentX: 0.65, percentY: 0.31, color: SmartColors.smartRed, size: 50),
                        _HeatmapSpot(maxWidth: maxWidth, maxHeight: maxHeight, percentX: 0.28, percentY: 0.23, color: SmartColors.smartGreen, size: 30),
                        _HeatmapSpot(maxWidth: maxWidth, maxHeight: maxHeight, percentX: 0.04, percentY: 0.93, color: SmartColors.smartRed, size: 55),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Paradas con mayor demanda actual:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: stops.take(5).length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final stop = stops[index];
                final demandCount = (20 - stop.order) * 2;
                
                Color demandColor;
                Color demandBgColor;
                
                if (demandCount > 25) {
                  demandColor = SmartColors.smartRed;
                  demandBgColor = SmartColors.smartLightRed;
                } else if (demandCount > 15) {
                  demandColor = SmartColors.smartYellow;
                  demandBgColor = SmartColors.smartLightYellow;
                } else {
                  demandColor = SmartColors.smartGreen;
                  demandBgColor = SmartColors.smartLightGreen;
                }

                return SmartRouteCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: demandBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.people, color: demandColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('A ${stop.order * 2} min', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$demandCount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: demandColor)),
                          const Text('personas', style: TextStyle(fontSize: 10, color: SmartColors.smartGray)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapSpot extends StatelessWidget {
  final double maxWidth;
  final double maxHeight;
  final double percentX;
  final double percentY;
  final Color color;
  final double size;

  const _HeatmapSpot({
    required this.maxWidth,
    required this.maxHeight,
    required this.percentX,
    required this.percentY,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final x = (maxWidth * percentX) - (size * 1.5);
    final y = (maxHeight * percentY) - (size * 1.5);

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
