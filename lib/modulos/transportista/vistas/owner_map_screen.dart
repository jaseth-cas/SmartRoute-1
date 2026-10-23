import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Pantalla de Monitoreo GPS de Flota para el Transportista / Dueño de Autobuses.
/// Muestra todas las unidades escolares activas en un mapa OpenStreetMap real con
/// telemetría interactiva, velocidad, chofer asignado y capacidad de cupos.
class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final MapController _mapController = MapController();
  final List<BusMock> buses = MockData.buses;

  // Coordenadas simuladas para los dos autobuses principales en ruta escolar
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
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text(
          'Monitoreo GPS de Flota',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: SmartColors.smartBlue),
        ),
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
        actions: [
          IconButton(
            tooltip: 'Centrar en flota',
            icon: const Icon(Icons.my_location, color: SmartColors.smartBlue),
            onPressed: () {
              _mapController.move(const LatLng(9.9340, -84.0780), 15.0);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de estado de la flota
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: SmartColors.smartGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${buses.length} Unidades en Operación',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartColors.smartText),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SmartColors.smartLightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'GPS Satelital Activo',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                  ),
                ),
              ],
            ),
          ),

          // Mapa interactivo OpenStreetMap
          Expanded(
            flex: 3,
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
                // Trazo de ruta escolar
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _bus1Route,
                      color: SmartColors.smartBlue.withValues(alpha: 0.6),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                // Marcadores de autobuses
                MarkerLayer(
                  markers: [
                    // Bus 1
                    Marker(
                      point: bus1Pos,
                      width: 70,
                      height: 70,
                      child: GestureDetector(
                        onTap: () => _centerOnBus(bus1Pos, buses[0]),
                        child: _BusGpsMarker(
                          code: buses.isNotEmpty ? buses[0].code : 'BUS-01',
                          color: SmartColors.smartBlue,
                          isSelected: _selectedBus?.code == buses[0].code,
                        ),
                      ),
                    ),
                    // Bus 2 (si existe)
                    if (buses.length > 1)
                      Marker(
                        point: bus2Pos,
                        width: 70,
                        height: 70,
                        child: GestureDetector(
                          onTap: () => _centerOnBus(bus2Pos, buses[1]),
                          child: _BusGpsMarker(
                            code: buses[1].code,
                            color: SmartColors.smartGreen,
                            isSelected: _selectedBus?.code == buses[1].code,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Tarjeta interactiva del autobús seleccionado
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.directions_bus, color: SmartColors.smartBlue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedBus?.code ?? 'BUS-01',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              _selectedBus?.model ?? 'Toyota Coaster Escolar',
                              style: const TextStyle(fontSize: 12, color: SmartColors.smartGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _selectedBus?.status == 'En recorrido'
                            ? SmartColors.smartLightGreen
                            : SmartColors.smartLightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedBus?.status ?? 'En servicio',
                        style: TextStyle(
                          color: _selectedBus?.status == 'En recorrido'
                              ? SmartColors.smartGreen
                              : SmartColors.smartBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _TelemetryItem(
                      icon: Icons.person,
                      label: 'Chofer',
                      value: _selectedBus?.driverName ?? 'Juan Pérez',
                    ),
                    _TelemetryItem(
                      icon: Icons.event_seat,
                      label: 'Cupos',
                      value: '${_selectedBus?.seatsOccupied ?? 14}/${_selectedBus?.capacity ?? 16}',
                    ),
                    _TelemetryItem(
                      icon: Icons.speed,
                      label: 'Velocidad',
                      value: '${_selectedBus?.currentSpeedKmH ?? 38} km/h',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < buses.length; i++) ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _selectedBus?.code == buses[i].code
                                  ? SmartColors.smartBlue
                                  : SmartColors.smartBorder,
                              width: _selectedBus?.code == buses[i].code ? 2 : 1,
                            ),
                            backgroundColor: _selectedBus?.code == buses[i].code
                                ? SmartColors.smartLightBlue.withValues(alpha: 0.3)
                                : Colors.white,
                          ),
                          onPressed: () {
                            final targetPos = i == 0 ? bus1Pos : bus2Pos;
                            _centerOnBus(targetPos, buses[i]);
                          },
                          child: Text(
                            'Ver ${buses[i].code}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedBus?.code == buses[i].code
                                  ? SmartColors.smartBlue
                                  : SmartColors.smartGray,
                            ),
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
        ],
      ),
    );
  }
}

class _BusGpsMarker extends StatelessWidget {
  final String code;
  final Color color;
  final bool isSelected;

  const _BusGpsMarker({
    required this.code,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? SmartColors.smartText : color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? SmartColors.smartBlue : color,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? SmartColors.smartBlue : Colors.black).withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.directions_bus, color: color, size: 22),
        ),
      ],
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: SmartColors.smartGray),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: SmartColors.smartGray)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SmartColors.smartText),
        ),
      ],
    );
  }
}
