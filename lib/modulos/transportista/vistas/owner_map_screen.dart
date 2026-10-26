import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final MapController _mapController = MapController();
  final List<BusMock> buses = MockData.buses;

  final List<LatLng> _bus1Route = const [
    LatLng(9.9322, -84.0795),
    LatLng(9.9335, -84.0792),
    LatLng(9.9348, -84.0789),
    LatLng(9.9360, -84.0785),
    LatLng(9.9358, -84.0770),
    LatLng(9.9345, -84.0772),
    LatLng(9.9332, -84.0775),
    LatLng(9.9318, -84.0778),
  ];

  final List<LatLng> _bus2Route = const [
    LatLng(9.9358, -84.0770),
    LatLng(9.9345, -84.0772),
    LatLng(9.9332, -84.0775),
    LatLng(9.9318, -84.0778),
    LatLng(9.9322, -84.0795),
    LatLng(9.9335, -84.0792),
    LatLng(9.9348, -84.0789),
    LatLng(9.9360, -84.0785),
  ];

  int _bus1Index = 0;
  int _bus2Index = 0;
  Timer? _gpsTimer;
  BusMock? _selectedBus;

  @override
  void initState() {
    super.initState();
    _selectedBus = buses.isNotEmpty ? buses.first : null;
    _startGpsSimulation();
  }

  void _startGpsSimulation() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _bus1Index = (_bus1Index + 1) % _bus1Route.length;
          _bus2Index = (_bus2Index + 1) % _bus2Route.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  void _centerOnBus(LatLng position, BusMock bus) {
    setState(() {
      _selectedBus = bus;
    });
    _mapController.move(position, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final bus1Pos = _bus1Route[_bus1Index];
    final bus2Pos = _bus2Route[_bus2Index];

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // Mapa satelital interactivo
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(9.9340, -84.0780),
                  initialZoom: 15.2,
                  minZoom: 12.0,
                  maxZoom: 18.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartroute.smartroute_flutter',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _bus1Route,
                        color: SmartColors.deepPetrol.withValues(alpha: 0.6),
                        strokeWidth: 4.5,
                      ),
                      Polyline(
                        points: _bus2Route,
                        color: SmartColors.electricCyan.withValues(alpha: 0.6),
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Bus 1
                      Marker(
                        point: bus1Pos,
                        width: 74,
                        height: 74,
                        child: GestureDetector(
                          onTap: () => _centerOnBus(bus1Pos, buses[0]),
                          child: _BusGpsMarker(
                            code: buses.isNotEmpty ? buses[0].code : 'BUS-01',
                            isSelected: _selectedBus?.code == buses[0].code,
                          ),
                        ),
                      ),
                      // Bus 2
                      if (buses.length > 1)
                        Marker(
                          point: bus2Pos,
                          width: 74,
                          height: 74,
                          child: GestureDetector(
                            onTap: () => _centerOnBus(bus2Pos, buses[1]),
                            child: _BusGpsMarker(
                              code: buses[1].code,
                              isSelected: _selectedBus?.code == buses[1].code,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // HUD Superior Flotante Quivox
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NeumorphicBox(
                        isPill: true,
                        padding: const EdgeInsets.all(12),
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/owner_home');
                          }
                        },
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                      NeumorphicBox(
                        isPill: true,
                        isDark: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SmartColors.electricCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${buses.length} UNIDADES EN VIVO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NeumorphicBox(
                        isPill: true,
                        padding: const EdgeInsets.all(12),
                        onTap: () {
                          _mapController.move(const LatLng(9.9340, -84.0780), 15.0);
                        },
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Selector de unidades flotante
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < buses.length; i++) ...[
                        NeumorphicBox(
                          isPill: true,
                          isDark: _selectedBus?.code == buses[i].code,
                          onTap: () {
                            final targetPos = i == 0 ? bus1Pos : bus2Pos;
                            _centerOnBus(targetPos, buses[i]);
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            buses[i].code,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: _selectedBus?.code == buses[i].code
                                  ? SmartColors.electricCyan
                                  : SmartColors.deepBlack,
                            ),
                          ),
                        ),
                        if (i < buses.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

            // Tarjeta Inferior de Telemetría Quivox
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: NeumorphicBox(
                    borderRadius: 26,
                    padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            NeumorphicBox(
                              isPill: true,
                              isDark: true,
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.directions_bus_rounded,
                                color: SmartColors.electricCyan,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedBus?.code ?? 'BUS-01',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                                Text(
                                  _selectedBus?.model ?? 'Toyota HiAce',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: SmartColors.deepPetrol.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        NeumorphicBox(
                          isPill: true,
                          isDark: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Text(
                            (_selectedBus?.status ?? 'EN SERVICIO').toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: SmartColors.electricCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Contenedor Inset con datos telemáticos
                    NeumorphicBox(
                      isInset: true,
                      borderRadius: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _TelemetryItem(
                            label: 'CHOFER',
                            value: _selectedBus?.driverName ?? 'Juan Pérez',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: SmartColors.deepPetrol.withValues(alpha: 0.15),
                          ),
                          _TelemetryItem(
                            label: 'CUPOS',
                            value:
                                '${_selectedBus?.seatsOccupied ?? 14}/${_selectedBus?.capacity ?? 16}',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: SmartColors.deepPetrol.withValues(alpha: 0.15),
                          ),
                          _TelemetryItem(
                            label: 'VELOCIDAD',
                            value: '${_selectedBus?.currentSpeedKmH ?? 38} km/h',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
      ),
    );
  }
}

class _BusGpsMarker extends StatelessWidget {
  final String code;
  final bool isSelected;

  const _BusGpsMarker({
    required this.code,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeumorphicBox(
          isPill: true,
          isDark: true,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            code,
            style: GoogleFonts.jetBrainsMono(
              color: isSelected ? SmartColors.electricCyan : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 3),
        NeumorphicBox(
          isPill: true,
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.directions_bus_rounded,
            color: isSelected ? SmartColors.electricCyan : SmartColors.deepPetrol,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final String label;
  final String value;

  const _TelemetryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: SmartColors.deepPetrol.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: SmartColors.deepBlack,
          ),
        ),
      ],
    );
  }
}
