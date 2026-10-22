import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

class _SimulatedMapScreenState extends State<SimulatedMapScreen> {
  String lastUpdate = "Hace unos segundos";
  bool isUpdating = false;

  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  // Ruta simulada de los buses para no dejar el mapa vacío
  final List<LatLng> fullLoopPath = const [
    LatLng(9.9322, -84.0795),
    LatLng(9.9335, -84.0792),
    LatLng(9.9348, -84.0789),
    LatLng(9.9360, -84.0785),
    LatLng(9.9358, -84.0770),
    LatLng(9.9345, -84.0772),
    LatLng(9.9332, -84.0775),
    LatLng(9.9318, -84.0778),
  ];

  int currentPointIndex = 0;
  Timer? loopTimer;

  @override
  void initState() {
    super.initState();
    _determinePosition();

    // Mover el bus cada 2 segundos
    loopTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isUpdating && mounted) {
        setState(() {
          currentPointIndex = (currentPointIndex + 1) % fullLoopPath.length;
        });
      }
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLocation = false);
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLocation = false);
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoadingLocation = false);
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 15.5);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    loopTimer?.cancel();
    super.dispose();
  }

  void _syncData() async {
    setState(() => isUpdating = true);
    await _determinePosition();
    await Future.delayed(const Duration(milliseconds: 500));
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

    final isUToB = currentPointIndex <= 3;
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
        title: const Text('Mapa Real (Tu Ubicación)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                text: "Mapa centrado en tu ubicación real (GPS).",
                icon: Icons.my_location,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AspectRatio(
                aspectRatio: 1024 / 800,
                child: Container(
                  decoration: BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SmartColors.smartBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentPosition ?? const LatLng(9.9335, -84.0785),
                            initialZoom: 15.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.smartroute',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: [...fullLoopPath, fullLoopPath.first],
                                  color: SmartColors.smartBlue,
                                  strokeWidth: 4.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                if (_currentPosition != null)
                                  Marker(
                                    point: _currentPosition!,
                                    width: 40,
                                    height: 40,
                                    child: _buildUserMarker(),
                                  ),
                                Marker(
                                  point: fullLoopPath[currentPointIndex],
                                  width: 60,
                                  height: 60,
                                  child: _buildBusMarker(bus?.code ?? "BUS-01", SmartColors.smartBlue),
                                ),
                                Marker(
                                  point: fullLoopPath[(currentPointIndex + 4) % fullLoopPath.length],
                                  width: 60,
                                  height: 60,
                                  child: _buildBusMarker("BUS-02", SmartColors.smartGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isLoadingLocation)
                          Container(
                            color: Colors.white.withValues(alpha: 0.7),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: SmartColors.smartBlue),
                                  SizedBox(height: 12),
                                  Text("Obteniendo tu ubicación...", style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
                                ],
                              ),
                            ),
                          ),
                        if (isUpdating)
                          Container(
                            color: Colors.white.withValues(alpha: 0.3),
                            child: const Center(
                              child: CircularProgressIndicator(color: SmartColors.smartBlue),
                            ),
                          ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: Colors.white,
                            onPressed: _syncData,
                            child: const Icon(Icons.my_location, color: SmartColors.smartBlue),
                          ),
                        ),
                      ],
                    ),
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
                            child: _MapStatusInfo(label: 'Estado', value: 'Conectado', color: SmartColors.smartGreen),
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
                      label: const Text('Centrar GPS', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildUserMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusMarker(String busCode, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
