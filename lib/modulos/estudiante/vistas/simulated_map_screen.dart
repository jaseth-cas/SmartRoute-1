import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';

class SimulatedMapScreen extends StatefulWidget {
  final String routeCode;
  final String stopCode;

  const SimulatedMapScreen({
    super.key,
    required this.routeCode,
    required this.stopCode,
  });

  @override
  State<SimulatedMapScreen> createState() => _SimulatedMapScreenState();
}

class _SimulatedMapScreenState extends State<SimulatedMapScreen> with SingleTickerProviderStateMixin {
  String lastUpdate = "Hace unos segundos";
  bool isUpdating = false;

  final List<Offset> fullLoopPath = const [
    // Segment 1
    Offset(0.89, 0.96), Offset(0.85, 0.79), Offset(0.82, 0.66),
    Offset(0.80, 0.53), Offset(0.73, 0.42), Offset(0.65, 0.31),
    Offset(0.49, 0.21), Offset(0.46, 0.15), Offset(0.38, 0.10),
    Offset(0.31, 0.16), Offset(0.28, 0.23), Offset(0.25, 0.29),
    Offset(0.19, 0.49), Offset(0.11, 0.69), Offset(0.07, 0.81),
    Offset(0.04, 0.93),
    // Segment 2
    Offset(0.04, 0.93), Offset(0.16, 0.58), Offset(0.19, 0.49),
    Offset(0.23, 0.38), Offset(0.63, 0.25), Offset(0.65, 0.31),
    Offset(0.73, 0.42), Offset(0.80, 0.53), Offset(0.82, 0.66),
    Offset(0.85, 0.79), Offset(0.89, 0.96),
  ];

  int currentPointIndex = 0;
  Timer? loopTimer;
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    
    _positionAnimation = Tween<Offset>(
      begin: fullLoopPath[currentPointIndex],
      end: fullLoopPath[currentPointIndex],
    ).animate(_animationController);

    loopTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!isUpdating && mounted) {
        final nextIndex = (currentPointIndex + 1) % fullLoopPath.length;
        setState(() {
          _positionAnimation = Tween<Offset>(
            begin: fullLoopPath[currentPointIndex],
            end: fullLoopPath[nextIndex],
          ).animate(_animationController);
          currentPointIndex = nextIndex;
        });
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    loopTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _syncData() async {
    setState(() => isUpdating = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        lastUpdate = "Actualizado ahora";
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(widget.routeCode);
    final bus = MockData.getBusByCode(route?.busCode ?? "BUS-01");

    final isUToB = currentPointIndex <= 15;
    final currentDisplayRoute = isUToB ? "Universidad → Boulevard" : "Boulevard → Universidad";
    final currentVia = isUToB ? "VÍA ALTA" : "VÍA BAJA";

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
        title: const Text('Simulador GPS en Bucle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        currentRoute: '/map',
        onNavigate: (route) => context.go(route),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: InfoBanner(
                text: "Bucle infinito: Universidad ↔ Boulevard (Ambos sentidos)",
                icon: Icons.autorenew,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 1024 / 680,
                child: Container(
                  decoration: BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SmartColors.smartBorder),
                  ),
                  child: Stack(
                    children: [
                      // Map image
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/img.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _positionAnimation,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              // Bus 1 coordinates
                              final x1 = constraints.maxWidth * _positionAnimation.value.dx - 18;
                              final y1 = constraints.maxHeight * _positionAnimation.value.dy - 18;
                              
                              // Bus 2 coordinates (slightly behind or offset)
                              final p2Index = (currentPointIndex + 6) % fullLoopPath.length;
                              final p2NextIndex = (p2Index + 1) % fullLoopPath.length;
                              final p2Val = Offset.lerp(fullLoopPath[p2Index], fullLoopPath[p2NextIndex], _animationController.value)!;
                              final x2 = constraints.maxWidth * p2Val.dx - 18;
                              final y2 = constraints.maxHeight * p2Val.dy - 18;

                              return Stack(
                                children: [
                                  Positioned(
                                    left: x2,
                                    top: y2,
                                    child: _buildBusMarker("BUS-02", SmartColors.smartGreen),
                                  ),
                                  Positioned(
                                    left: x1,
                                    top: y1,
                                    child: _buildBusMarker(bus?.code ?? "BUS-01", SmartColors.smartBlue),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      if (isUpdating)
                        Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          child: const Center(
                            child: CircularProgressIndicator(color: SmartColors.smartBlue),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SmartRouteCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Trayecto actual', style: TextStyle(fontSize: 10, color: SmartColors.smartGray)),
                              Text(currentDisplayRoute, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          width: 1,
                          color: SmartColors.smartBorder,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Sentido', style: TextStyle(fontSize: 10, color: SmartColors.smartGray)),
                              Text(currentVia, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: SmartColors.smartBorder),
                    const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _MapStatusInfo(label: 'Velocidad', value: '${30 + math.Random().nextInt(11)} km/h', color: SmartColors.smartBlue),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: _MapStatusInfo(label: 'Estado', value: 'Simulando', color: SmartColors.smartGreen),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MapStatusInfo(label: 'Actualizado', value: lastUpdate, color: SmartColors.smartGray),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isUpdating ? null : _syncData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Sincronizar', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartColors.smartBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/eta/${widget.routeCode}/${widget.stopCode}'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: SmartColors.smartBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Ver ETA', style: TextStyle(color: SmartColors.smartBlue, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }

  Widget _buildBusMarker(String busCode, Color color) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.directions_bus, color: color, size: 18),
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
    );
  }
}

class _MapStatusInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MapStatusInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: SmartColors.smartGray)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
