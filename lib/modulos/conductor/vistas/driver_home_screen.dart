import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/gps_permission_helper.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/route_optimizer_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/telemetry_simulation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final MapController _mapController = MapController();
  double _currentZoom = 16.2;
  bool _showSchools = true;
  SchoolLocation? _selectedSchool;
  bool gpsActive = true;

  BusMock? _bus;
  List<StudentPassengerMock> _passengers = [];
  bool _hasLoadedDriverData = false;
  StreamSubscription? _attendanceSub;
  StreamSubscription<StudentPassengerMock>? _locationSub;
  RealtimeChannel? _studentsRealtimeChannel;
  StudentService? _studentService;

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

  // Motor de navegación en vivo basado en Dijkstra + OSRM + BusTelemetryController
  BusTelemetryController? _telemetryController;
  final OsrmRoutingService _osrmRoutingService = OsrmRoutingService();
  late final RouteOptimizerService _routeOptimizer =
      RouteOptimizerService(osrmService: _osrmRoutingService);
  List<({String name, LatLng point})> _coveredSchoolDestinations = const [];
  LatLng _currentBusPos = AppConstants.penonomeCenter;
  double _currentBearing = -160.0;
  int _currentSegmentIndex = 0;
  double _currentSpeed = 38.0;
  bool _isAutoTracking = true;
  DateTime _lastCameraMoveTime = DateTime.fromMillisecondsSinceEpoch(0);
  List<LatLng> schoolBusPath = [
    AppConstants.penonomeCenter,
    AppConstants.defaultSchoolPoint,
  ];

  @override
  void initState() {
    super.initState();
    _currentBusPos = schoolBusPath.first;
    _updateClock();

    // Reloj en vivo de telemetría CCTV
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _updateClock());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(GpsPermissionHelper.ensureLocationReady(context, showPromptIfDisabled: false));
      BusService? busService;
      try {
        busService = context.read<BusService>();
      } catch (_) {}
      _telemetryController = BusTelemetryController(busService: busService)
        ..addListener(_onTelemetryTick);
      _centerOnBus();
      _loadDriverData();
      _setupRealtimeSubscription();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _locationSub?.cancel();
    _studentService?.unsubscribeChannel(_studentsRealtimeChannel);
    _clockTimer?.cancel();
    _telemetryController?.removeListener(_onTelemetryTick);
    _telemetryController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverData({bool silent = false}) async {
    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();
      final session = context.read<SessionManager>().currentSession;

      BusMock? bus;
      if (session != null && session.userId.isNotEmpty) {
        bus = await busService.getBusByDriver(session.userId);
      }

      if (bus == null) {
        if (mounted) {
          setState(() {
            _bus = null;
            _passengers = [];
            _hasLoadedDriverData = true;
          });
        }
        return;
      }

      final students = await studentService.getStudentsByBus(bus.code);

      if (mounted) {
        setState(() {
          _bus = bus;
          _passengers = students;
          _hasLoadedDriverData = true;
          if (bus!.latitude != null && bus.longitude != null) {
            _currentBusPos = LatLng(bus.latitude!, bus.longitude!);
          }
          _currentSpeed =
              bus.currentSpeedKmH > 0 ? bus.currentSpeedKmH.toDouble() : 34.0;
        });
      }

      // Actualizar polilínea de calles OSRM en segundo plano sin bloquear la UI
      unawaited(_refreshOsrmStreetRoute(students, bus));
    } catch (e) {
      debugPrint('Error cargando datos del conductor: $e');
      if (mounted) {
        setState(() => _hasLoadedDriverData = true);
      }
    }
  }

  /// Calcula la ruta óptima compartida (Dijkstra + OSRM multi-colegio) y alimenta
  /// el controlador de telemetría para avanzar sobre la polilínea real.
  Future<void> _refreshOsrmStreetRoute(
    List<StudentPassengerMock> students,
    BusMock bus,
  ) async {
    final optimized = await _routeOptimizer.buildOptimalRoute(
      bus: bus,
      students: students,
    );
    if (!mounted) return;

    setState(() {
      _coveredSchoolDestinations = optimized.orderedSchools;
      if (optimized.polylinePoints.length >= 2) {
        schoolBusPath = optimized.polylinePoints;
      }
    });

    final ctrl = _telemetryController;
    if (ctrl != null && optimized.polylinePoints.length >= 2) {
      ctrl.updateRoute(optimized, preserveProgress: true);
      if (gpsActive && !ctrl.isPlaying && ctrl.mode == TelemetryMode.simulated) {
        ctrl.start();
      }
    }
  }

  void _setupRealtimeSubscription() {
    final attendanceService = context.read<AttendanceService>();
    final studentService = context.read<StudentService>();
    _studentService = studentService;

    _attendanceSub = attendanceService.streamTodayAttendance().listen((_) {
      if (mounted) {
        _loadDriverData(silent: true);
      }
    });
    _locationSub = StudentService.locationUpdatesStream.listen((updated) {
      if (mounted && (_bus == null || updated.busCode == _bus!.code)) {
        _loadDriverData(silent: true);
      }
    });
    _studentsRealtimeChannel = studentService.subscribeToStudentChanges(
      channelName: 'driver_home_estudiantes_${DateTime.now().millisecondsSinceEpoch}',
      onChanged: () {
        if (mounted) {
          _loadDriverData(silent: true);
        }
      },
    );
  }

  void _updateClock() {
    final now = DateTime.now();
    _liveClock = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  void _onTelemetryTick() {
    final ctrl = _telemetryController;
    if (!mounted || ctrl == null) return;
    final prevPos = _currentBusPos;
    final nextPos = ctrl.currentPosition;
    final moved = (nextPos.latitude - prevPos.latitude).abs() > 1e-7 ||
        (nextPos.longitude - prevPos.longitude).abs() > 1e-7;

    setState(() {
      _currentBusPos = nextPos;
      _currentSpeed = ctrl.currentSpeedKmH;
      _currentSegmentIndex = ctrl.currentVertexIndex;
      if (moved) {
        _currentBearing = math.atan2(
              nextPos.longitude - prevPos.longitude,
              nextPos.latitude - prevPos.latitude,
            ) *
            180 /
            math.pi;
      }
    });

    if (_isAutoTracking) {
      final now = DateTime.now();
      if (now.difference(_lastCameraMoveTime).inMilliseconds >= 120) {
        _lastCameraMoveTime = now;
        _mapController.move(_currentBusPos, _currentZoom);
      }
    }
  }

  String _getNavigationInstruction(int segmentIndex) {
    final ctrl = _telemetryController;
    if (ctrl != null && ctrl.nextStopLabel.isNotEmpty) {
      return 'Próx. parada: ${ctrl.nextStopLabel}';
    }
    final schools = _coveredSchoolDestinations.map((s) => s.name).toList();
    if (schools.isNotEmpty) {
      return 'Ruta hacia: ${schools.join(' • ')}';
    }
    final fallback = BusService.extractCoveredSchools(
      _passengers.where((p) => p.status != PassengerStatus.absent),
      fallbackSchool: _bus?.schoolName,
    );
    return fallback.isNotEmpty
        ? 'Ruta hacia: ${fallback.join(' • ')}'
        : 'Ruta escolar activa en Penonomé';
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
    final bus = _bus;
    final allPassengers = _passengers;
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
  Widget _buildDriverMap(BusMock? bus) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final safeSegIdx = schoolBusPath.isNotEmpty
        ? _currentSegmentIndex.clamp(0, schoolBusPath.length - 1)
        : 0;
    final traveledPoints = schoolBusPath.isNotEmpty
        ? <LatLng>[
            ...schoolBusPath.sublist(0, safeSegIdx + 1),
            _currentBusPos,
          ]
        : <LatLng>[];

    final remainingPoints = schoolBusPath.length > safeSegIdx + 1
        ? <LatLng>[
            _currentBusPos,
            ...schoolBusPath.sublist(safeSegIdx + 1),
          ]
        : <LatLng>[];

    final schoolMarkers = _coveredSchoolDestinations.isNotEmpty
        ? _coveredSchoolDestinations
        : [
            (
              name: bus?.schoolName ?? 'Colegio destino',
              point: schoolBusPath.isNotEmpty
                  ? schoolBusPath.last
                  : AppConstants.resolveSchoolPoint(bus?.schoolName),
            ),
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
            // Marcadores dinámicos de todos los colegios cubiertos por los estudiantes del bus
            ...schoolMarkers.map(
              (dest) => Marker(
                point: dest.point,
                width: isMobile ? 30 : 145,
                height: isMobile ? 30 : 56,
                child: _buildLocationPin(
                  title: dest.name.toUpperCase(),
                  subtitle: 'Destino escolar',
                  icon: Icons.school_rounded,
                  pinColor: SmartColors.smartGreen,
                  isMobile: isMobile,
                ),
              ),
            ),

            // Marcadores dinámicos de domicilios de TODOS los estudiantes asignados al bus
            ..._passengers
                .where((s) => s.pickupLatitude != null && s.pickupLongitude != null)
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
            if (bus != null)
              Marker(
                point: _currentBusPos,
                width: 180,
                height: 96,
                child: _buildSmoothNavigationBusMarker(
                  code: bus.code,
                  speed: _currentSpeed,
                  bearing: _currentBearing,
                ),
              ),

            // Marcadores de los Colegios y Escuelas de Penonomé mapeados con Punto Rojo
            if (_showSchools)
              ...AppConstants.penonomeSchools.map((school) {
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
                        '• DESTINO: ${(_bus?.schoolName ?? "SIN ASIGNAR").toUpperCase()}',
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
                          '${bus?.seatsOccupied ?? _passengers.length}/${bus?.capacity ?? 0} ALUMNOS • CABINA OK',
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
    final waitingStudents =
        _passengers.where((p) => p.status == PassengerStatus.waiting).toList();
    final nextStudent = waitingStudents.firstOrNull;
    final hasBus = _bus != null;
    final coveredSchools = _coveredSchoolDestinations.isNotEmpty
        ? _coveredSchoolDestinations.map((s) => s.name).toList()
        : BusService.extractCoveredSchools(
            _passengers.where((p) => p.status != PassengerStatus.absent),
            fallbackSchool: _bus?.schoolName,
          );
    final schoolsSummary = coveredSchools.isNotEmpty
        ? 'Colegios: ${coveredSchools.join(' • ')}'
        : 'Ruta escolar activa';
    final title = !hasBus
        ? (_hasLoadedDriverData ? 'Sin unidad asignada' : 'Sincronizando unidad...')
        : (nextStudent != null ? nextStudent.name : schoolsSummary);
    final subtitle = !hasBus
        ? 'Contacta al transportista para vincular un bus'
        : (nextStudent != null
            ? '${nextStudent.pickupAddress} • ${waitingStudents.length} espera(n)'
            : '${_passengers.length} alumno(s) en manifiesto');

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
                color: hasBus ? SmartColors.smartLightGreen : SmartColors.neuInset,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hasBus ? 'EN RUTA' : 'PENDIENTE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  color: hasBus ? SmartColors.smartGreen : SmartColors.smartGray,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: SmartColors.deepBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          subtitle,
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
  Widget _buildDriverHeaderPill(String driverName, BusMock? bus, {bool isMobile = false}) {
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
                    bus != null
                        ? '${bus.code} • ${bus.routeName ?? "Ruta en Penonomé"}'
                        : (_hasLoadedDriverData ? 'SIN BUS ASIGNADO' : 'Cargando unidad...'),
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
              StatusChip(text: bus?.status ?? 'SIN BUS'),
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
