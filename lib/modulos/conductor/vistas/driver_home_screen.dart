import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/user_options_bar.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  double _currentZoom = 16.2;
  bool _showSchools = true;
  SchoolLocation? _selectedSchool;
  bool gpsActive = true;

  BusMock? _bus;
  List<StudentPassengerMock> _passengers = [];
  StreamSubscription? _attendanceSub;
  Timer? _gpsTimer;

  // Coordenadas base para la simulación de telemetría GPS
  double _currentLat = 8.5270;
  double _currentLng = -80.3512;

  // Monitor CCTV retrovisor interior en vivo
  bool _isCameraExpanded = true;
  final int _activeCamIndex = 0;
  Timer? _clockTimer;
  String _liveClock = '07:14:28';
  final List<String> _cameraAngles = const [
    'CAM-01 [PASILLO]',
    'CAM-02 [PUERTA]',
    'CAM-03 [CABINA]',
  ];

  // Motor de navegación en vivo: movimiento fluido y seguimiento de cámara suave
  late AnimationController _navController;
  LatLng _currentBusPos = const LatLng(8.5270, -80.3512);
  double _currentBearing = -160.0;
  int _currentSegmentIndex = 0;
  double _currentSpeed = 38.0;
  bool _isAutoTracking = true;
  DateTime _lastCameraMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  List<double> _segmentDistances = [];
  double _totalDistance = 0.0;

  // Ruta 1: Desde la Casa del Estudiante hasta la Parada de Recogida (Ruta de acceso en Vía Cristo Rey)
  final List<LatLng> studentWalkPath = const [
    LatLng(8.5284, -80.3582), // Casa del Estudiante
    LatLng(8.5281, -80.3565),
    LatLng(8.5289, -80.3551),
    LatLng(8.5268, -80.3533),
    LatLng(8.5242, -80.3522), // Parada en Vía hacia Sonadora
  ];

  // Ruta 2: Recorrido del Autobús Colegial en vivo (trazada sobre calles reales vía OSRM)
  final OsrmRoutingService _osrmRoutingService = OsrmRoutingService();
  List<LatLng> schoolBusPath = [
    const LatLng(8.5270, -80.3512), // Origen ruta colegial
    const LatLng(8.5242, -80.3522), // Parada de recogida del estudiante
    const LatLng(8.5215, -80.3532), // Vía hacia Sonadora
    const LatLng(8.5186, -80.3541), // Vía hacia Sonadora sur
    const LatLng(8.5172, -80.3540), // Giro de acceso a barriada escolar
    const LatLng(8.5160, -80.3522), // Calle de conexión
    const LatLng(8.5146, -80.3508), // Avenida escolar
    const LatLng(8.5156, -80.3500), // Acceso vehicular
    const LatLng(8.5154, -80.3482), // Colegio San José (Destino)
  ];

  @override
  void initState() {
    super.initState();
    _initDistances();
    _currentBusPos = schoolBusPath.first;
    _updateClock();

    // Reloj en vivo de telemetría CCTV
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateClock());
    });

    // Animador de desplazamiento continuo y suave (duración calibrada para velocidad realista de colegial)
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 45),
    )..addListener(_onNavTick)
     ..addStatusListener((status) {
       if (status == AnimationStatus.completed) {
         _navController.forward(from: 0.0);
       }
     });

    _navController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnBus();
      _loadDriverData();
      _setupRealtimeSubscription();
      _startGpsSimulation();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _gpsTimer?.cancel();
    _clockTimer?.cancel();
    _navController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData({bool silent = false}) async {
    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();
      final session = context.read<SessionManager>().currentSession;

      // Ejecutar consulta de bus y estudiantes en paralelo con Future.wait
      final results = await Future.wait([
        (session != null && session.userId.isNotEmpty)
            ? busService.getBusByDriver(session.userId)
            : busService.getBusByCode('BUS-01'),
        studentService.getStudentsByBus('BUS-01'),
      ]);

      final bus = (results[0] as BusMock?) ??
          MockData.getBusByCode('BUS-01') ??
          MockData.buses.first;

      final students = bus.code == 'BUS-01'
          ? (results[1] as List<StudentPassengerMock>)
          : await studentService.getStudentsByBus(bus.code);

      final effectiveStudents = students.isNotEmpty
          ? students
          : MockData.getPassengersByBus(bus.code);

      if (mounted) {
        setState(() {
          _bus = bus;
          _passengers = effectiveStudents;
          _currentLat = bus.latitude ?? _currentBusPos.latitude;
          _currentLng = bus.longitude ?? _currentBusPos.longitude;
        });
      }

      // Actualizar polilínea de calles OSRM en segundo plano sin bloquear la UI
      unawaited(_refreshOsrmStreetRoute(effectiveStudents));
    } catch (e) {
      debugPrint('Error cargando datos del conductor: $e');
    }
  }

  /// Calcula la polilínea real sobre calles transitables usando OSRM (`OsrmRoutingService.getDrivingRoute`)
  /// conectando los puntos de recogida de los estudiantes activos hasta el colegio de destino.
  Future<void> _refreshOsrmStreetRoute(List<StudentPassengerMock> students) async {
    final activeWaypoints = <LatLng>[
      const LatLng(8.5270, -80.3512), // Punto de salida de la ruta
    ];

    for (final s in students) {
      if (s.status != PassengerStatus.absent &&
          s.pickupLatitude != null &&
          s.pickupLongitude != null) {
        activeWaypoints.add(LatLng(s.pickupLatitude!, s.pickupLongitude!));
      }
    }

    activeWaypoints.add(const LatLng(8.5154, -80.3482)); // Destino Colegio San José

    final streetGeometry = await _osrmRoutingService.getDrivingRoute(activeWaypoints);
    if (mounted && streetGeometry.length >= 2) {
      setState(() {
        schoolBusPath = streetGeometry;
        _initDistances();
        if (_currentSegmentIndex >= schoolBusPath.length - 1) {
          _currentSegmentIndex = 0;
        }
      });
    }
  }

  void _setupRealtimeSubscription() {
    final attendanceService = context.read<AttendanceService>();
    _attendanceSub = attendanceService.streamTodayAttendance().listen((_) {
      if (mounted) {
        _loadDriverData(silent: true);
      }
    });
  }

  void _startGpsSimulation() {
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!gpsActive || _bus == null || !mounted) return;

      _currentLat = _currentBusPos.latitude;
      _currentLng = _currentBusPos.longitude;

      final busService = context.read<BusService>();
      busService.updateBusLocation(
        busCode: _bus!.code,
        latitude: _currentLat,
        longitude: _currentLng,
        speedKmH: _currentSpeed.round(),
      );
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    _liveClock = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _initDistances() {
    _segmentDistances = [];
    _totalDistance = 0.0;
    for (int i = 0; i < schoolBusPath.length - 1; i++) {
      final d = _calculateDistance(schoolBusPath[i], schoolBusPath[i + 1]);
      _segmentDistances.add(d);
      _totalDistance += d;
    }
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    final latAvg = (p1.latitude + p2.latitude) / 2 * math.pi / 180;
    final dy = (p2.latitude - p1.latitude) * 111320;
    final dx = (p2.longitude - p1.longitude) * 111320 * math.cos(latAvg);
    return math.sqrt(dx * dx + dy * dy);
  }

  ({LatLng position, double bearing, int segmentIndex}) _interpolateNavPosition(double progress) {
    if (_segmentDistances.isEmpty || _totalDistance == 0) {
      return (position: schoolBusPath.first, bearing: -160.0, segmentIndex: 0);
    }
    final targetDistance = progress * _totalDistance;
    double accum = 0.0;

    for (int i = 0; i < _segmentDistances.length; i++) {
      final d = _segmentDistances[i];
      if (accum + d >= targetDistance || i == _segmentDistances.length - 1) {
        final segT = d > 0 ? ((targetDistance - accum) / d).clamp(0.0, 1.0) : 0.0;
        final p1 = schoolBusPath[i];
        final p2 = schoolBusPath[i + 1];
        final lat = p1.latitude + segT * (p2.latitude - p1.latitude);
        final lon = p1.longitude + segT * (p2.longitude - p1.longitude);
        final bearing = math.atan2(p2.longitude - p1.longitude, p2.latitude - p1.latitude) * 180 / math.pi;
        return (position: LatLng(lat, lon), bearing: bearing, segmentIndex: i);
      }
      accum += d;
    }
    return (position: schoolBusPath.last, bearing: 0.0, segmentIndex: _segmentDistances.length - 1);
  }

  void _onNavTick() {
    if (!mounted) return;
    final navData = _interpolateNavPosition(_navController.value);

    setState(() {
      _currentBusPos = navData.position;
      _currentBearing = navData.bearing;
      _currentSegmentIndex = navData.segmentIndex;
      // Fluctuación realista de velocidad urbana entre 33 y 41 km/h
      _currentSpeed = 37.0 + math.sin(_navController.value * 28 * math.pi) * 3.8;
    });

    // Seguimiento suave del mapa de la ubicación del vehículo (limitado a ~12 FPS de cámara para rendimiento óptimo)
    if (_isAutoTracking) {
      final now = DateTime.now();
      if (now.difference(_lastCameraMoveTime).inMilliseconds >= 80) {
        _lastCameraMoveTime = now;
        _mapController.move(_currentBusPos, _currentZoom);
      }
    }
  }

  String _getNavigationInstruction(int segmentIndex) {
    switch (segmentIndex) {
      case 0:
        return "Avanza por Vía hacia Sonadora hacia Parada de recogida";
      case 1:
        return "Próxima detención: Parada Asignada (Estudiantes esperan)";
      case 2:
        return "Continúa recto por Vía hacia Sonadora (950 m)";
      case 3:
        return "En 120 m: Gira a la izquierda hacia Barriada Escolar";
      case 4:
        return "Giro completado: Ingrese por Calle de Conexión";
      case 5:
        return "Avanza por Avenida Escolar (320 m)";
      case 6:
        return "En 80 m: Gira a la derecha hacia Acceso Vehicular";
      case 7:
        return "Destino en 120 m: Colegio San José a la derecha";
      default:
        return "Ruta hacia Colegio San José";
    }
  }

  IconData _getManeuverIcon(int segmentIndex) {
    switch (segmentIndex) {
      case 3:
      case 4:
        return Icons.turn_left_rounded;
      case 6:
        return Icons.turn_right_rounded;
      case 7:
        return Icons.school_rounded;
      case 1:
        return Icons.directions_bus_rounded;
      default:
        return Icons.straight_rounded;
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = math.min(_currentZoom + 1.0, 18.5);
      _mapController.move(_currentBusPos, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = math.max(_currentZoom - 1.0, 11.0);
      _mapController.move(_currentBusPos, _currentZoom);
    });
  }

  void _centerOnBus() {
    setState(() {
      _isAutoTracking = true;
      _currentZoom = 16.4;
    });
    _mapController.move(_currentBusPos, _currentZoom);
  }

  void _openFacialScanner() {
    context.push('/facial_checkin').then((_) {
      if (mounted) {
        _loadDriverData(silent: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final bus = _bus ?? MockData.getBusByCode('BUS-01') ?? MockData.buses.first;
    final allPassengers = _passengers.isNotEmpty
        ? _passengers
        : MockData.getPassengersByBus(bus.code);
    final onboardCount = allPassengers.where((p) => p.status == PassengerStatus.onboard).length;
    final absentCount = allPassengers.where((p) => p.status == PassengerStatus.absent).length;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: Stack(
        children: [
          // 1. Mapa Interactivo Completo de borde a borde (Ocupa toda la ventana de arriba a abajo)
          Positioned.fill(
            child: _buildDriverMap(bus),
          ),

          // 2 & 3. HUD Superior Responsivo (En teléfono usa una fila limpia de ancho completo sin solapamiento)
          if (isMobile)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildDriverHeaderPill(
                      session?.name ?? "Juan Pérez",
                      bus,
                      isMobile: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const UserAppBarActions(
                    buttonSize: 38,
                    noTrailingPadding: true,
                  ),
                ],
              ),
            )
          else ...[
            // Cabina Conductor (Alineada en la esquina superior izquierda en Web/Desktop)
            Positioned(
              top: 16,
              left: 16,
              child: _buildDriverHeaderPill(session?.name ?? "Juan Pérez", bus),
            ),

            // Componentes del Lateral Superior Derecho: GPS Navegación Activa y Opciones de Usuario
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: SmartColors.neuInset,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.deepBlack.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: gpsActive ? SmartColors.vibrantCyan : SmartColors.primaryCrimson,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GPS NAVEGACIÓN ACTIVA',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const UserAppBarActions(
                    buttonSize: 42,
                    noTrailingPadding: true,
                  ),
                ],
              ),
            ),
          ],

          // 4. Panel de Retroalimentación en Vivo: Cámara Interna del Autobús (CCTV Retrovisor AI)
          if (_isCameraExpanded)
            Positioned(
              top: isMobile ? MediaQuery.paddingOf(context).top + 78 : 72,
              right: isMobile ? 64 : 76,
              child: _buildLiveCCTVCameraPanel(bus),
            ),

          // 5. Botón de Alerta / Reanudar Seguimiento si el conductor movió el mapa manualmente
          if (!_isAutoTracking)
            Positioned(
              top: isMobile ? MediaQuery.paddingOf(context).top + 74 : 16,
              left: isMobile ? 12 : 340,
              child: _buildResumeTrackingPill(),
            ),

          // 6. Controles Flotantes del Mapa
          Positioned(
            top: isMobile ? MediaQuery.paddingOf(context).top + 78 : 72,
            right: isMobile ? 12 : 16,
            child: _buildMapFloatingControls(),
          ),

          // 7. Ficha de Colegio Seleccionado (si se seleccionó un punto rojo)
          if (_selectedSchool != null)
            Positioned(
              top: 146,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _buildSelectedSchoolOverlay(),
                ),
              ),
            ),

          // 8. Barra Reducida del Conductor (Próxima parada y navegación turn-by-turn) flotando sobre el mapa
          Positioned(
            bottom: 84,
            left: 14,
            right: 14,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: _buildReducedDriverBottomBar(
                  bus: bus,
                  onboardCount: onboardCount,
                  absentCount: absentCount,
                ),
              ),
            ),
          ),

          // 9. Barra de opciones de navegación (Ruta, Alumnos, Incidente) flotando directamente sobre el mapa
          Positioned(
            bottom: 6,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DriverBottomBar(
                currentRoute: '/driver_home',
                onNavigate: (route) => context.go(route),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // MAPA INTERACTIVO CON POLILÍNEAS Y NAVEGACIÓN
  // ==========================================
  Widget _buildDriverMap(dynamic bus) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final traveledPoints = <LatLng>[
      ...schoolBusPath.sublist(0, _currentSegmentIndex + 1),
      _currentBusPos,
    ];

    final remainingPoints = <LatLng>[
      _currentBusPos,
      ...schoolBusPath.sublist(_currentSegmentIndex + 1),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentBusPos,
        initialZoom: _currentZoom,
        minZoom: 11.0,
        maxZoom: 18.5,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && _isAutoTracking) {
            setState(() {
              _isAutoTracking = false;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartroute.smartroute_flutter',
        ),
        PolylineLayer(
          polylines: [
            // Ruta del Estudiante (Casa -> Parada)
            Polyline(
              points: studentWalkPath,
              color: SmartColors.primaryCrimson.withValues(alpha: 0.25),
              strokeWidth: 8.0,
            ),
            Polyline(
              points: studentWalkPath,
              color: SmartColors.primaryCrimson,
              strokeWidth: 4.5,
            ),

            // Tramo ya recorrido del Bus (en azul noche atenuado)
            if (traveledPoints.length >= 2) ...[
              Polyline(
                points: traveledPoints,
                color: SmartColors.deepBlue.withValues(alpha: 0.35),
                strokeWidth: 6.0,
              ),
            ],

            // Tramo por recorrer (Camino a seguir iluminado con halo brillante)
            if (remainingPoints.length >= 2) ...[
              Polyline(
                points: remainingPoints,
                color: SmartColors.vibrantCyan.withValues(alpha: 0.35),
                strokeWidth: 10.0,
              ),
              Polyline(
                points: remainingPoints,
                color: SmartColors.vibrantCyan,
                strokeWidth: 5.5,
              ),
            ],
          ],
        ),
        MarkerLayer(
          markers: [
            // Marcador 1: Casa del Estudiante
            Marker(
              point: studentWalkPath.first,
              width: isMobile ? 30 : 130,
              height: isMobile ? 30 : 56,
              child: _buildLocationPin(
                title: "CASA DE MATEO",
                subtitle: "Salida 06:45 AM",
                icon: Icons.home_rounded,
                pinColor: SmartColors.primaryCrimson,
                isMobile: isMobile,
              ),
            ),

            // Marcador 2: Parada de Recogida
            Marker(
              point: studentWalkPath.last,
              width: isMobile ? 30 : 140,
              height: isMobile ? 30 : 56,
              child: _buildLocationPin(
                title: "PARADA ASIGNADA",
                subtitle: "Vía Sonadora // 07:05 AM",
                icon: Icons.directions_bus_rounded,
                pinColor: SmartColors.deepBlue,
                isMobile: isMobile,
              ),
            ),

            // Marcador 3: Colegio San José (Destino Escolar)
            Marker(
              point: schoolBusPath.last,
              width: isMobile ? 30 : 130,
              height: isMobile ? 30 : 56,
              child: _buildLocationPin(
                title: "COLEGIO SAN JOSÉ",
                subtitle: "Llegada 07:20 AM",
                icon: Icons.school_rounded,
                pinColor: SmartColors.smartGreen,
                isMobile: isMobile,
              ),
            ),

            // Marcadores dinámicos de domicilios de estudiantes registrados con coordenadas GPS
            ...(_passengers.isNotEmpty ? _passengers : MockData.passengers)
                .where((s) => s.pickupLatitude != null && s.pickupLongitude != null && s.id != 1)
                .map((student) {
              final isAbsent = student.status == PassengerStatus.absent;
              final isOnboard = student.status == PassengerStatus.onboard;
              return Marker(
                point: LatLng(student.pickupLatitude!, student.pickupLongitude!),
                width: isMobile ? 30 : 145,
                height: isMobile ? 30 : 56,
                child: _buildLocationPin(
                  title: 'CASA: ${student.name.toUpperCase()}',
                  subtitle: isAbsent
                      ? 'AUSENTE (Omitida)'
                      : isOnboard
                          ? 'A BORDO'
                          : student.pickupAddress,
                  icon: Icons.home_rounded,
                  pinColor: isAbsent
                      ? SmartColors.smartGray
                      : isOnboard
                          ? SmartColors.smartGreen
                          : SmartColors.deepBlue,
                  isMobile: isMobile,
                ),
              );
            }),

            // Marcador 4: Vehículo Colegial con Movimiento Fluido y Orientación de Rumbo
            Marker(
              point: _currentBusPos,
              width: 180,
              height: 96,
              child: _buildSmoothNavigationBusMarker(
                code: bus?.code ?? "BUS-01",
                speed: _currentSpeed,
                bearing: _currentBearing,
              ),
            ),

            // Marcadores de los 9 Colegios y Escuelas de Penonomé mapeados con Punto Rojo
            if (_showSchools)
              ...MockData.penonomeSchools.map((school) {
                final isSelected = _selectedSchool?.id == school.id;
                return Marker(
                  point: LatLng(school.latitude, school.longitude),
                  width: 140,
                  height: 52,
                  child: _buildSchoolRedPointMarker(school, isSelected: isSelected),
                );
              }),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // MARCADOR CON MOVIMIENTO FLUIDO Y RUMBO
  // ==========================================
  Widget _buildSmoothNavigationBusMarker({
    required String code,
    required double speed,
    required double bearing,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: SmartColors.deepBlack,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: SmartColors.vibrantCyan, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.5,
                height: 6.5,
                decoration: const BoxDecoration(
                  color: SmartColors.vibrantCyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$code • ${speed.toStringAsFixed(0)} KM/H',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.ghostWhite,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartColors.vibrantCyan.withValues(alpha: 0.22),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SmartColors.deepBlue.withValues(alpha: 0.28),
              ),
            ),
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SmartColors.deepBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: SmartColors.deepBlack.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.navigation_rounded,
                  color: SmartColors.vibrantCyan,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // PANEL DE GUÍA TURN-BY-TURN ESTILO WAZE
  // ==========================================
  Widget _buildTurnByTurnNavigationBanner() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SmartColors.deepBlack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: SmartColors.deepBlack.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: SmartColors.vibrantCyan.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: SmartColors.vibrantCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getManeuverIcon(_currentSegmentIndex),
              color: SmartColors.vibrantCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getNavigationInstruction(_currentSegmentIndex),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: SmartColors.ghostWhite,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${_currentSpeed.toStringAsFixed(0)} KM/H',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.vibrantCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• DESTINO: COL. SAN JOSÉ',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.smartGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumeTrackingPill() {
    return GestureDetector(
      onTap: _centerOnBus,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SmartColors.primaryCrimson,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: SmartColors.primaryCrimson.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              'REANUDAR SEGUIMIENTO',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANEL DE RETROALIMENTACIÓN: CÁMARA INTERIOR EN VIVO
  // ==========================================
  Widget _buildLiveCCTVCameraPanel(dynamic bus) {
    if (!_isCameraExpanded) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: NeumorphicBox(
        padding: const EdgeInsets.all(6),
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/bus_interior_cctv.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: SmartColors.deepBlack,
                        child: const Center(
                          child: Icon(Icons.videocam_rounded, color: SmartColors.vibrantCyan, size: 36),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.25, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: SmartColors.primaryCrimson,
                                borderRadius: BorderRadius.circular(4.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 3.5),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REC 1080p',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24, width: 0.6),
                              ),
                              child: Text(
                                _cameraAngles[_activeCamIndex],
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: SmartColors.vibrantCyan,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24, width: 0.6),
                              ),
                              child: Text(
                                _liveClock,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            GestureDetector(
                              onTap: () => setState(() => _isCameraExpanded = false),
                              child: Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 0.6),
                                ),
                                child: const Icon(
                                  Icons.close_fullscreen_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${bus.seatsOccupied ?? 8}/${bus.capacity ?? 14} ALUMNOS • CABINA OK',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SmartColors.smartGreen.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NORMAL',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }

  // ==========================================
  // BARRA CENTRAL INFERIOR REDUCIDA DEL CONDUCTOR
  // ==========================================
  Widget _buildReducedDriverBottomBar({
    required dynamic bus,
    int? onboardCount,
    int? absentCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        return NeumorphicBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(24),
          child: isNarrow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildStopIcon(),
                        const SizedBox(width: 10),
                        Expanded(child: _buildNextStopInfo()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTurnByTurnNavigationBanner(),
                  ],
                )
              : Row(
                  children: [
                    _buildStopIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 5,
                      child: _buildNextStopInfo(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 6,
                      child: _buildTurnByTurnNavigationBanner(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStopIcon() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: SmartColors.deepBlue.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.location_on_rounded, color: SmartColors.deepBlue, size: 20),
      ),
    );
  }

  Widget _buildNextStopInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              'PRÓXIMA PARADA',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: SmartColors.smartGray,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: SmartColors.smartLightGreen,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'EN RUTA',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.smartGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Colegio San José - Puerta 1',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: SmartColors.deepBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Calle 127 # 45-20 • 2 Estudiantes esperan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: SmartColors.deepBlue,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENTES FLOTANTES DEL CONDUCTOR & MAPA
  // ==========================================
  Widget _buildDriverHeaderPill(String driverName, dynamic bus, {bool isMobile = false}) {
    return GestureDetector(
      onTap: _centerOnBus,
      child: NeumorphicBox(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 8 : 10,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              width: isMobile ? 32 : 36,
              height: isMobile ? 32 : 36,
              decoration: BoxDecoration(
                color: SmartColors.deepBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.airline_seat_recline_normal_rounded,
                color: SmartColors.deepBlue,
                size: isMobile ? 18 : 20,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isMobile ? 'CONDUCTOR' : 'CONDUCTOR ASIGNADO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: SmartColors.smartGray,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _isAutoTracking
                              ? SmartColors.vibrantCyan.withValues(alpha: 0.18)
                              : SmartColors.primaryCrimson.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isAutoTracking ? 'GPS ACTIVO' : 'PAUSADO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: _isAutoTracking ? SmartColors.deepBlue : SmartColors.primaryCrimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    driverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 12 : 13,
                      fontWeight: FontWeight.w900,
                      color: SmartColors.deepBlack,
                    ),
                  ),
                  Text(
                    '${bus.code} • ${bus.routeName ?? "Ruta Escolar Norte"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 10 : 10.5,
                      fontWeight: FontWeight.w600,
                      color: SmartColors.deepBlue,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 12),
              StatusChip(text: bus.status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapFloatingControls() {
    return Column(
      children: [
        _buildColumnButton(
          icon: Icons.add_rounded,
          onTap: _zoomIn,
          iconColor: SmartColors.deepBlack,
        ),
        const SizedBox(height: 8),
        _buildColumnButton(
          icon: Icons.remove_rounded,
          onTap: _zoomOut,
          iconColor: SmartColors.deepBlack,
        ),
        const SizedBox(height: 10),
        _buildColumnButton(
          icon: _isAutoTracking ? Icons.navigation_rounded : Icons.my_location_rounded,
          onTap: _centerOnBus,
          isDark: _isAutoTracking,
          iconColor: _isAutoTracking ? SmartColors.vibrantCyan : SmartColors.deepBlack,
        ),
        const SizedBox(height: 8),
        _buildColumnButton(
          icon: Icons.school_rounded,
          onTap: () {
            setState(() {
              _showSchools = !_showSchools;
            });
          },
          iconColor: _showSchools ? SmartColors.primaryCrimson : SmartColors.smartGray,
        ),
        const SizedBox(height: 8),
        _buildColumnButton(
          icon: Icons.videocam_rounded,
          onTap: () {
            setState(() {
              _isCameraExpanded = !_isCameraExpanded;
            });
          },
          iconColor: _isCameraExpanded ? SmartColors.primaryCrimson : SmartColors.deepBlack,
        ),
        const SizedBox(height: 12),
        Tooltip(
          message: 'Terminal Facial AI (Abordaje)',
          child: _buildColumnButton(
            icon: Icons.face_retouching_natural_rounded,
            onTap: _openFacialScanner,
            isDark: true,
            iconColor: SmartColors.vibrantCyan,
          ),
        ),
      ],
    );
  }

  Widget _buildColumnButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isDark = false,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: NeumorphicBox(
        isPill: true,
        isDark: isDark,
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: Center(
          child: Icon(icon, size: 19, color: iconColor ?? SmartColors.deepBlack),
        ),
      ),
    );
  }

  Widget _buildSelectedSchoolOverlay() {
    final school = _selectedSchool!;
    return NeumorphicBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SmartColors.primaryCrimson.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: SmartColors.primaryCrimson, width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.school_rounded, color: SmartColors.primaryCrimson, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: SmartColors.primaryCrimson,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PUNTO ROJO // PENONOMÉ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.primaryCrimson,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  school.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SmartColors.deepBlack,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  school.address,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: SmartColors.smartGray,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              setState(() => _isAutoTracking = false);
              _mapController.move(LatLng(school.latitude, school.longitude), 17.2);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SmartColors.deepBlack,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.my_location_rounded, size: 14, color: SmartColors.vibrantCyan),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _selectedSchool = null),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SmartColors.neuInset,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 16, color: SmartColors.smartGray),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPin({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color pinColor,
    bool isMobile = false,
  }) {
    if (isMobile) {
      return Tooltip(
        message: '$title • $subtitle',
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.2),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.28),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      );
    }

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

  Widget _buildSchoolRedPointMarker(SchoolLocation school, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSchool = school;
          _isAutoTracking = false;
        });
        _mapController.move(LatLng(school.latitude, school.longitude), 16.8);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: BoxDecoration(
              color: isSelected ? SmartColors.deepBlack : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SmartColors.primaryCrimson,
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: SmartColors.primaryCrimson.withValues(alpha: isSelected ? 0.35 : 0.20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5.5,
                  height: 5.5,
                  decoration: const BoxDecoration(
                    color: SmartColors.primaryCrimson,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    school.shortName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SmartColors.primaryCrimson.withValues(alpha: 0.25),
                ),
              ),
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SmartColors.primaryCrimson,
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: SmartColors.primaryCrimson.withValues(alpha: 0.65),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
