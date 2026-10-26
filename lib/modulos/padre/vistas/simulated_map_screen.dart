import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

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
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;
  bool isUpdating = false;
  String _activeTab = 'Tracking'; // 'Tracking', 'Analytics', 'Detalles'

  // Ruta 1: Desde la Casa del Estudiante hasta la Parada de Recogida (Ruta de acceso en Vía Cristo Rey)
  final List<LatLng> studentWalkPath = const [
    LatLng(8.5284, -80.3582), // Casa del Estudiante
    LatLng(8.5281, -80.3565),
    LatLng(8.5289, -80.3551),
    LatLng(8.5268, -80.3533),
    LatLng(8.5242, -80.3522), // Parada en Vía hacia Sonadora
  ];

  // Ruta 2: Recorrido del Autobús Colegial en vivo (Vía hacia Sonadora -> Colegio San José)
  final List<LatLng> schoolBusPath = const [
    LatLng(8.5270, -80.3512), // Origen ruta colegial
    LatLng(8.5242, -80.3522), // Parada de recogida del estudiante
    LatLng(8.5215, -80.3532), // Vía hacia Sonadora
    LatLng(8.5186, -80.3541), // Vía hacia Sonadora sur
    LatLng(8.5172, -80.3540), // Giro de acceso a barriada escolar
    LatLng(8.5160, -80.3522), // Calle de conexión
    LatLng(8.5146, -80.3508), // Avenida escolar
    LatLng(8.5156, -80.3500), // Acceso vehicular
    LatLng(8.5154, -80.3482), // Colegio San José (Destino)
  ];

  int currentPointIndex = 0;
  Timer? loopTimer;
  double _currentZoom = 15.2;

  @override
  void initState() {
    super.initState();
    _determinePosition();

    // Loop de movimiento de autobús colegial cada 2.5 seg
    loopTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!isUpdating && mounted) {
        setState(() {
          currentPointIndex = (currentPointIndex + 1) % schoolBusPath.length;
        });
      }
    });
  }

  @override
  void dispose() {
    loopTimer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, _currentZoom);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _syncData() async {
    setState(() => isUpdating = true);
    await _determinePosition();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => isUpdating = false);
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = math.min(_currentZoom + 1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = math.max(_currentZoom - 1.0, 11.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _centerOnBus() {
    final busPos = schoolBusPath[currentPointIndex];
    _mapController.move(busPos, 16.2);
  }

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(widget.routeCode);
    final bus = MockData.getBusByCode(route?.busCode ?? "BUS-01");

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 920;

            if (isDesktop) {
              return Row(
                children: [
                  // Sidebar Telemático Fijo (Estilo Dash de Flotas)
                  SizedBox(
                    width: 420,
                    child: _buildTelematicsPanel(bus, isDesktop: true),
                  ),

                  // Área Principal del Mapa a Pantalla Completa
                  Expanded(
                    child: Stack(
                      children: [
                        _buildMapView(bus),
                        if (_isLoadingLocation)
                          Positioned(
                            top: 24,
                            left: 20,
                            child: NeumorphicBox(
                              isPill: true,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: SmartColors.vibrantCyan),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CALIBRANDO GPS...',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: SmartColors.deepBlue,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildMapFloatingControls(),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // Vista Móvil / Tablet: Mapa completo + Panel Telemático Deslizable
              return Stack(
                children: [
                  Positioned.fill(
                    child: _buildMapView(bus),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: NeumorphicBox(
                      isPill: true,
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/student_home');
                        }
                      },
                      child: const Icon(Icons.arrow_back_rounded, size: 20, color: SmartColors.deepBlack),
                    ),
                  ),
                  _buildMapFloatingControls(isMobile: true),
                  DraggableScrollableSheet(
                    initialChildSize: 0.40,
                    minChildSize: 0.16,
                    maxChildSize: 0.88,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: SmartColors.neuBackground,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              color: SmartColors.deepBlack.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: SmartColors.smartGray.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTelematicsPanelContent(bus, isDesktop: false),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/map',
          onNavigate: (route) => context.go(route),
        ),
      ),
    );
  }

  // Mapa Interactivo con Rutas en Vivo Conectadas (Casa de Estudiante -> Parada -> Escuela)
  Widget _buildMapView(dynamic bus) {
    final busPos = schoolBusPath[currentPointIndex];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(8.5220, -80.3535), // Penonomé - Vía hacia Sonadora
        initialZoom: _currentZoom,
        minZoom: 11.0,
        maxZoom: 18.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartroute.smartroute_flutter',
        ),
        // Polilíneas con halo neumórfico para ambas rutas conectadas
        PolylineLayer(
          polylines: [
            // 1. Sombra de la Ruta del Estudiante (Casa -> Parada)
            Polyline(
              points: studentWalkPath,
              color: SmartColors.primaryCrimson.withValues(alpha: 0.25),
              strokeWidth: 8.0,
            ),
            // Línea de la Ruta del Estudiante (Casa -> Parada) en Carmesí Alerta / Acceso
            Polyline(
              points: studentWalkPath,
              color: SmartColors.primaryCrimson,
              strokeWidth: 4.8,
            ),

            // 2. Sombra de la Ruta del Bus Colegial (Parada -> Colegio)
            Polyline(
              points: schoolBusPath,
              color: SmartColors.deepBlue.withValues(alpha: 0.35),
              strokeWidth: 9.0,
            ),
            // Línea Troncal del Bus Colegial en Cian Eléctrico
            Polyline(
              points: schoolBusPath,
              color: SmartColors.vibrantCyan,
              strokeWidth: 5.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Marcador 1: Casa del Estudiante (Punto de Origen)
            Marker(
              point: studentWalkPath.first,
              width: 130,
              height: 56,
              child: _buildLocationPin(
                title: "CASA DE MATEO",
                subtitle: "Salida 06:45 AM",
                icon: Icons.home_rounded,
                pinColor: SmartColors.primaryCrimson,
              ),
            ),

            // Marcador 2: Parada de Recogida (Punto de Conexión en Vía hacia Sonadora)
            Marker(
              point: studentWalkPath.last,
              width: 140,
              height: 56,
              child: _buildLocationPin(
                title: "PARADA ASIGNADA",
                subtitle: "Vía Sonadora // 07:05 AM",
                icon: Icons.directions_bus_rounded,
                pinColor: SmartColors.deepBlue,
              ),
            ),

            // Marcador 3: Colegio San José (Destino Escolar)
            Marker(
              point: schoolBusPath.last,
              width: 130,
              height: 56,
              child: _buildLocationPin(
                title: "COLEGIO SAN JOSÉ",
                subtitle: "Llegada 07:20 AM",
                icon: Icons.school_rounded,
                pinColor: SmartColors.smartGreen,
              ),
            ),

            // Marcador 4: Bus Colegial Activo (Moviéndose en vivo)
            Marker(
              point: busPos,
              width: 84,
              height: 84,
              child: _buildBusMarker(
                code: bus?.code ?? "BUS-01",
                label: "42 km/h",
                isActive: true,
              ),
            ),

            // Chip Flotante en Ruta sobre Vía hacia Sonadora
            Marker(
              point: schoolBusPath[2],
              width: 154,
              height: 34,
              child: _buildFloatingStatusChip(
                text: "Vía hacia Sonadora",
                icon: Icons.alt_route_rounded,
                bgColor: SmartColors.deepBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Controles flotantes sobre el mapa
  Widget _buildMapFloatingControls({bool isMobile = false}) {
    return Positioned(
      top: isMobile ? 70 : 24,
      right: 20,
      child: Column(
        children: [
          NeumorphicBox(
            isPill: true,
            padding: const EdgeInsets.all(12),
            onTap: _zoomIn,
            child: const Icon(Icons.add_rounded, size: 20, color: SmartColors.deepBlack),
          ),
          const SizedBox(height: 10),
          NeumorphicBox(
            isPill: true,
            padding: const EdgeInsets.all(12),
            onTap: _zoomOut,
            child: const Icon(Icons.remove_rounded, size: 20, color: SmartColors.deepBlack),
          ),
          const SizedBox(height: 14),
          NeumorphicBox(
            isPill: true,
            isDark: true,
            padding: const EdgeInsets.all(12),
            onTap: _centerOnBus,
            child: const Icon(Icons.directions_bus_rounded, size: 20, color: SmartColors.vibrantCyan),
          ),
          const SizedBox(height: 10),
          NeumorphicBox(
            isPill: true,
            padding: const EdgeInsets.all(12),
            onTap: _syncData,
            child: isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: SmartColors.deepBlue),
                  )
                : const Icon(Icons.my_location_rounded, size: 20, color: SmartColors.deepBlue),
          ),
        ],
      ),
    );
  }

  // Panel lateral telemático (Desktop)
  Widget _buildTelematicsPanel(dynamic bus, {required bool isDesktop}) {
    return Container(
      decoration: BoxDecoration(
        color: SmartColors.neuBackground,
        border: Border(
          right: BorderSide(color: SmartColors.neuBorder.withValues(alpha: 0.7), width: 1.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: _buildTelematicsPanelContent(bus, isDesktop: isDesktop),
        ),
      ),
    );
  }

  // Contenido interno del panel telemático
  Widget _buildTelematicsPanelContent(dynamic bus, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra superior de acciones
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            NeumorphicBox(
              isPill: true,
              padding: const EdgeInsets.all(10),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/student_home');
                }
              },
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: SmartColors.deepBlack),
            ),
            NeumorphicBox(
              isPill: true,
              isDark: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: SmartColors.vibrantCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '3 VEHÍCULOS ACTIVOS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: SmartColors.ghostWhite,
                    ),
                  ),
                ],
              ),
            ),
            NeumorphicBox(
              isPill: true,
              padding: const EdgeInsets.all(10),
              onTap: _syncData,
              child: const Icon(Icons.refresh_rounded, size: 18, color: SmartColors.deepBlack),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Ficha del Conductor & Score Circular (Inspirado en la imagen de referencia)
        NeumorphicBox(
          padding: const EdgeInsets.all(18),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus?.driverName ?? 'Alex Williams',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ruta Norte • Colegio San José',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SmartColors.smartGray,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '37 548 km',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+ 0.28',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: SmartColors.smartGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Dial Circular Neumórfico de Driver Score / Puntualidad
              _buildDriverScoreDial(score: "4.85", label: "SCORE"),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Banner de Alerta / Estado Técnico
        NeumorphicBox(
          isInset: true,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: SmartColors.smartGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Inspección telemática al día // Enlace GPS 4G',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: SmartColors.deepBlack,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Selector de Pestañas: Tracking, Analytics, Detalles
        Row(
          children: [
            _buildTabPill('Tracking'),
            const SizedBox(width: 8),
            _buildTabPill('Analytics'),
            const SizedBox(width: 8),
            _buildTabPill('Detalles'),
          ],
        ),

        const SizedBox(height: 18),

        // Contenido según la pestaña seleccionada
        if (_activeTab == 'Tracking') ...[
          // Tarjeta de la Unidad / Bus Escolar
          _buildBusVehicleCard(bus),

          const SizedBox(height: 18),

          // Timeline de Paradas e Incidencias en tiempo real
          Text(
            'LÍNEA DE TIEMPO & EVENTOS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: SmartColors.smartGray,
            ),
          ),
          const SizedBox(height: 12),
          _buildStopTimeline(),
        ] else if (_activeTab == 'Analytics') ...[
          _buildAnalyticsView(bus),
        ] else ...[
          _buildDetailsView(bus),
        ],

        const SizedBox(height: 24),

        // Botón de acción principal
        NeumorphicBox(
          isDark: true,
          borderRadius: BorderRadius.circular(999),
          padding: const EdgeInsets.symmetric(vertical: 16),
          onTap: () => context.push('/eta/${widget.routeCode}/${widget.stopCode}'),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, color: SmartColors.vibrantCyan, size: 18),
              const SizedBox(width: 10),
              Text(
                'VER TIEMPO ESTIMADO (ETA)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: SmartColors.ghostWhite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  // Dial Circular de Score (reproduciendo la foto de referencia)
  Widget _buildDriverScoreDial({required String score, required String label}) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: SmartColors.ghostWhite,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            offset: const Offset(-3, -3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: SmartColors.deepBlue.withValues(alpha: 0.12),
            offset: const Offset(3, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: 0.88,
              strokeWidth: 4.5,
              backgroundColor: SmartColors.neuInset,
              valueColor: const AlwaysStoppedAnimation<Color>(SmartColors.vibrantCyan),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.deepBlack,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: SmartColors.smartGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Píldora de Pestaña
  Widget _buildTabPill(String title) {
    final isSelected = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? SmartColors.deepBlack : SmartColors.neuInset,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SmartColors.deepBlack.withValues(alpha: 0.2),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? SmartColors.vibrantCyan : SmartColors.smartGray,
            ),
          ),
        ),
      ),
    );
  }

  // Tarjeta de Centro de Control y Telemetría del Vehículo Escolar (Inspirado en la referencia automotriz)
  Widget _buildBusVehicleCard(dynamic bus) {
    return NeumorphicBox(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header técnico superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: SmartColors.deepBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BUS 01 // COLEGIAL',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: SmartColors.ghostWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'CONSUMO // 9.2 L/100KM',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: SmartColors.smartGray,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'TELEMETRÍA EN VIVO',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: SmartColors.deepBlack,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SmartColors.smartLightGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: SmartColors.smartGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'ACTIVO',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.smartGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Visualización 3D del Vehículo Colegial con Sombra de Contacto
          Center(
            child: SizedBox(
              height: 145,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sombra elíptica realista en el piso
                  Positioned(
                    bottom: 4,
                    child: Container(
                      width: 210,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: SmartColors.deepBlack.withValues(alpha: 0.28),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Imagen del autobús colegial amarillo
                  Image.asset(
                    'assets/images/colegial_bus.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.directions_bus_rounded,
                        size: 80,
                        color: SmartColors.deepBlue,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Barra de Métricas Técnicas (RANGE | MILEAGE | REMAINING)
          NeumorphicBox(
            isInset: true,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricCol(
                    label: 'AUTONOMÍA',
                    subLabel: 'RANGE',
                    value: '326 KM',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: SmartColors.deepBlue.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _buildMetricCol(
                    label: 'KILOMETRAJE',
                    subLabel: 'MILEAGE',
                    value: '12 683 KM',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: SmartColors.deepBlue.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _buildMetricCol(
                    label: 'COMBUSTIBLE',
                    subLabel: 'REMAINING',
                    value: '65 L (82%)',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Información de la Ruta Escolar del Estudiante
          NeumorphicBox(
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRAYECTO DEL ESTUDIANTE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: SmartColors.deepBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SmartColors.smartLightGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'EN CURSO',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.smartGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 16, color: SmartColors.vibrantCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Casa de Mateo ➔ Colegio San José',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '8 de 14 estudiantes a bordo • Llegada estimada: 07:20 AM',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: SmartColors.smartGray,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Barra de turnos y franja horaria original de la jornada escolar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimelineHour('06:00'),
              _buildTimelineHour('08:00'),
              _buildTimelineHour('10:00'),
              _buildTimelineHour('12:00'),
              _buildTimelineHour('14:00'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(flex: 3, child: Container(height: 7, color: SmartColors.deepBlue)),
                Expanded(flex: 2, child: Container(height: 7, color: SmartColors.vibrantCyan)),
                Expanded(flex: 1, child: Container(height: 7, color: SmartColors.primaryCrimson)),
                Expanded(flex: 4, child: Container(height: 7, color: SmartColors.neuInset)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String subLabel,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          subLabel,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: SmartColors.smartGray,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: SmartColors.deepBlack,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: SmartColors.deepBlue.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHour(String label) {
    return Text(
      label,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: SmartColors.smartGray,
      ),
    );
  }

  // Timeline de Paradas e Incidencias (como en la foto de referencia)
  Widget _buildStopTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          time: '06:45',
          title: 'Salida de Terminal Central',
          subtitle: 'Inicio de recorrido matutino',
          badgeText: 'On time',
          badgeColor: SmartColors.smartGreen,
          icon: Icons.check_circle_rounded,
          isCompleted: true,
          isLast: false,
        ),
        _buildTimelineItem(
          time: '07:05',
          title: 'Residencial Las Palmas',
          subtitle: 'Abordaron 4 estudiantes',
          badgeText: 'On time',
          badgeColor: SmartColors.smartGreen,
          icon: Icons.check_circle_rounded,
          isCompleted: true,
          isLast: false,
        ),
        _buildTimelineItem(
          time: '07:18',
          title: 'Cruce Av. Central',
          subtitle: 'Desaceleración preventiva por semáforo',
          badgeText: 'Evento en ruta',
          badgeColor: SmartColors.primaryCrimson,
          icon: Icons.warning_amber_rounded,
          isCompleted: false,
          isLast: false,
        ),
        _buildTimelineItem(
          time: '07:30',
          title: 'Tu Parada: Residencial El Valle',
          subtitle: 'Próxima detención programada',
          badgeText: 'ETA 12 min',
          badgeColor: SmartColors.vibrantCyan,
          icon: Icons.radio_button_checked_rounded,
          isCurrent: true,
          isCompleted: false,
          isLast: false,
        ),
        _buildTimelineItem(
          time: '07:50',
          title: 'Colegio San José (Destino)',
          subtitle: 'Llegada programada a puerta escolar',
          badgeText: 'Final',
          badgeColor: SmartColors.deepBlue,
          icon: Icons.school_rounded,
          isCompleted: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                time,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? SmartColors.deepBlack : SmartColors.smartGray,
                ),
              ),
            ),
          ),

          // Eje vertical y nodo
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? SmartColors.vibrantCyan
                      : (isCompleted ? SmartColors.ghostWhite : SmartColors.neuInset),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrent ? SmartColors.deepBlack : badgeColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 12,
                  color: isCurrent ? SmartColors.deepBlack : badgeColor,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? SmartColors.deepBlue.withValues(alpha: 0.3) : SmartColors.neuBorder,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Tarjeta del evento
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: NeumorphicBox(
                padding: const EdgeInsets.all(12),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                              color: SmartColors.deepBlack,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: SmartColors.smartGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Analytics
  Widget _buildAnalyticsView(dynamic bus) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'VELOCIDAD PROM.',
                value: '42 km/h',
                trend: '+4%',
                icon: Icons.speed_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'EFICIENCIA',
                value: '96.2%',
                trend: 'Óptima',
                icon: Icons.eco_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'FRENADAS BRUSCAS',
                value: '1 evento',
                trend: 'Bajo',
                icon: Icons.warning_amber_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'DISTANCIA RESTANTE',
                value: '4.8 km',
                trend: '14 min',
                icon: Icons.navigation_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String trend,
    required IconData icon,
  }) {
    return NeumorphicBox(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: SmartColors.smartGray,
                ),
              ),
              Icon(icon, size: 16, color: SmartColors.deepBlue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: SmartColors.deepBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: SmartColors.smartGreen,
            ),
          ),
        ],
      ),
    );
  }

  // Vista de Detalles
  Widget _buildDetailsView(dynamic bus) {
    return NeumorphicBox(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATOS DEL SERVICIO ESCOLAR',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: SmartColors.deepBlack,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Operador:', 'Transportes Escolar Unidos S.A.'),
          _buildDetailRow('Póliza de seguro:', 'POL-9921-VIGENTE'),
          _buildDetailRow('Capacidad:', '${bus?.capacity ?? 18} plazas escolares'),
          _buildDetailRow('Teléfono chofer:', '+507 6890-1122'),
          _buildDetailRow('Colegio destino:', 'Colegio San José - Campus Central'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: SmartColors.smartGray,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: SmartColors.deepBlack,
            ),
          ),
        ],
      ),
    );
  }

  // Marcador de Bus sobre el Mapa
  Widget _buildBusMarker({required String code, required String label, required bool isActive}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: SmartColors.deepBlack,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? SmartColors.vibrantCyan : SmartColors.smartGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                code,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.ghostWhite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isActive ? SmartColors.deepBlue : SmartColors.smartGray,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: SmartColors.vibrantCyan,
            size: 20,
          ),
        ),
      ],
    );
  }

  // Pin de Ubicación Estilizado para Casa, Parada y Escuela
  Widget _buildLocationPin({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color pinColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: SmartColors.ghostWhite,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: pinColor.withValues(alpha: 0.4), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.deepBlack,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w600,
                  color: SmartColors.smartGray,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.25),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ],
    );
  }

  // Chip Flotante de Estado en Ruta (como en la foto de referencia)
  Widget _buildFloatingStatusChip({
    required String text,
    required IconData icon,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
