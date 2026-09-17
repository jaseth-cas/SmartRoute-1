import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../theme/colors.dart';

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final buses = MockData.buses;
  
  final List<List<double>> fullLoopPath = [
    [0.89, 0.96], [0.85, 0.79], [0.82, 0.66], [0.80, 0.53],
    [0.73, 0.42], [0.65, 0.31], [0.49, 0.21], [0.46, 0.15],
    [0.38, 0.10], [0.31, 0.16], [0.28, 0.23], [0.25, 0.29],
    [0.19, 0.49], [0.11, 0.69], [0.07, 0.81], [0.04, 0.93],
    [0.04, 0.93], [0.16, 0.58], [0.19, 0.49], [0.23, 0.38],
    [0.63, 0.25], [0.65, 0.31], [0.73, 0.42], [0.80, 0.53],
    [0.82, 0.66], [0.85, 0.79], [0.89, 0.96]
  ];

  int index1 = 0;
  int index2 = 12; // Segundo bus empieza más adelante
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimationLoop();
  }

  void _startAnimationLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 4000), (timer) {
      if (mounted) {
        setState(() {
          index1 = (index1 + 1) % fullLoopPath.length;
          index2 = (index2 + 1) % fullLoopPath.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Mapa de la Flota', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/owner_home');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Flota Activa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SmartColors.smartText)),
                      Text('${buses.length} autobuses en línea', style: const TextStyle(fontSize: 14, color: SmartColors.smartGray)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AspectRatio(
              aspectRatio: 1024 / 680,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartColors.smartBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                        color: Colors.black.withValues(alpha: 0.2),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final maxHeight = constraints.maxHeight;

                          final point1 = fullLoopPath[index1];
                          final left1 = (maxWidth * point1[0]) - 18;
                          final top1 = (maxHeight * point1[1]) - 18;

                          final point2 = fullLoopPath[index2];
                          final left2 = (maxWidth * point2[0]) - 18;
                          final top2 = (maxHeight * point2[1]) - 18;

                          return Stack(
                            children: [
                              _BusAnimatedMarker(
                                left: left1,
                                top: top1,
                                busCode: buses.isNotEmpty ? buses[0].code : 'BUS-01',
                                color: SmartColors.smartBlue,
                              ),
                              _BusAnimatedMarker(
                                left: left2,
                                top: top2,
                                busCode: buses.length > 1 ? buses[1].code : 'BUS-02',
                                color: SmartColors.smartGreen,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusAnimatedMarker extends StatelessWidget {
  final double left;
  final double top;
  final String busCode;
  final Color color;

  const _BusAnimatedMarker({
    required this.left,
    required this.top,
    required this.busCode,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 3000),
      curve: Curves.linear,
      left: left,
      top: top,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(Icons.directions_bus, color: color, size: 20),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                busCode,
                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
