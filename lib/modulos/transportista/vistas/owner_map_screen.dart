import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/gps_permission_helper.dart';
import 'package:smartroute_flutter/nucleo/servicios/osrm_routing_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/route_optimizer_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/telemetry_simulation_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  static const List<Color> _busColorPalette = [
    Color(0xFF0077B6), // Azul Profundo
    Color(0xFF059669), // Esmeralda
    Color(0xFFEA580C), // Naranja
    Color(0xFF7C3AED), // Púrpura
    Color(0xFFDB2777), // Fucsia
    Color(0xFF0891B2), // Turquesa
  ];

  final MapController _mapController = MapController();
  final OsrmRoutingService _osrmRoutingService = OsrmRoutingService();
  late final RouteOptimizerService _routeOptimizer =
      RouteOptimizerService(osrmService: _osrmRoutingService);
  List<BusMock> buses = [];
  List<StudentPassengerMock> _students = [];
  Map<String, List<LatLng>> _busRoutes = {};
  Map<String, OptimizedBusRoute> _optimizedRoutes = {};
  Set<String> _selectedBusCodes = {};
  bool _hasInitializedFilter = false;

  StreamSubscription<List<BusMock>>? _busSubscription;
  Future<void> Function()? _unsubscribeRouteTriggers;
  BusTelemetryController? _telemetryController;

  BusMock? _selectedBus;
  StudentPassengerMock? _selectedStudent;
  bool _isRealtimeActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(GpsPermissionHelper.ensureLocationReady(context, showPromptIfDisabled: false));
      _initFleetMapData();
    });
  }

  Color _colorForBusCode(String busCode) {
    final idx = buses.indexWhere((b) => b.code == busCode);
    final safeIdx = idx >= 0 ? idx : busCode.hashCode.abs();
    return _busColorPalette[safeIdx % _busColorPalette.length];
  }

  void _toggleBusFilter(BusMock bus, LatLng targetPos) {
    setState(() {
      if (_selectedBusCodes.length == buses.length && buses.length > 1) {
        _selectedBusCodes = {bus.code};
      } else if (_selectedBusCodes.contains(bus.code)) {
        _selectedBusCodes = Set<String>.from(_selectedBusCodes)..remove(bus.code);
      } else {
        _selectedBusCodes = Set<String>.from(_selectedBusCodes)..add(bus.code);
      }

      if (_selectedBusCodes.length == 1) {
        final singleCode = _selectedBusCodes.first;
        _selectedBus = buses.firstWhere(
          (b) => b.code == singleCode,
          orElse: () => bus,
        );
      } else if (_selectedBusCodes.contains(bus.code)) {
        _selectedBus = bus;
      } else if (_selectedBusCodes.isNotEmpty) {
        _selectedBus = buses.firstWhere(
          (b) => _selectedBusCodes.contains(b.code),
          orElse: () => bus,
        );
      } else {
        _selectedBus = null;
      }
      _selectedStudent = null;
    });

    final activeBus = _selectedBus;
    if (activeBus != null) {
      final opt = _optimizedRoutes[activeBus.code];
      if (opt != null) {
        _telemetryController?.updateRoute(opt, preserveProgress: false);
      }
      if (_selectedBusCodes.contains(bus.code)) {
        _mapController.move(targetPos, 15.8);
      }
    }
  }

  void _toggleAllBusesFilter() {
    setState(() {
      if (_selectedBusCodes.length == buses.length) {
        _selectedBusCodes = {};
        _selectedBus = null;
      } else {
        _selectedBusCodes = buses.map((b) => b.code).toSet();
        if (buses.isNotEmpty) {
          _selectedBus ??= buses.first;
        }
      }
      _selectedStudent = null;
    });
  }

  Future<void> _initFleetMapData() async {
    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();
      _telemetryController = BusTelemetryController(busService: busService)
        ..addListener(_onTelemetryTick);

      AttendanceService attendanceService;
      try {
        attendanceService = context.read<AttendanceService>();
      } catch (_) {
        attendanceService = AttendanceService();
      }

      final results = await Future.wait([
        busService.getAllBuses(),
        studentService.getAllStudents(),
      ]);

      final realBuses = results[0] as List<BusMock>;
      final realStudents = results[1] as List<StudentPassengerMock>;

      if (mounted) {
        setState(() {
          buses = realBuses;
          _students = realStudents;
          if (!_hasInitializedFilter) {
            _selectedBusCodes = realBuses.map((b) => b.code).toSet();
            _hasInitializedFilter = true;
          }
          if (buses.isNotEmpty) {
            _selectedBus = buses.firstWhere(
              (b) => b.code == _selectedBus?.code,
              orElse: () => buses.first,
            );
          }
        });
      }

      unawaited(_refreshAllBusRoutes(realBuses, realStudents));

      // Suscripción Realtime a autobuses
      _busSubscription = busService.streamAllBuses().listen(
        (updatedBuses) {
          if (mounted && updatedBuses.isNotEmpty) {
            setState(() {
              buses = updatedBuses;
              _isRealtimeActive = true;
              if (_selectedBus != null) {
                _selectedBus = buses.firstWhere(
                  (b) => b.code == _selectedBus!.code,
                  orElse: () => buses.first,
                );
              } else {
                _selectedBus = buses.first;
              }
            });
            unawaited(_refreshAllBusRoutes(updatedBuses, _students));
          }
        },
        onError: (err) {
          debugPrint('Aviso Stream Realtime buses: $err');
        },
      );

      // Suscripción reactiva unificada (estudiantes_pasajeros + asistencia_diaria + stream local)
      _unsubscribeRouteTriggers = RouteOptimizerService.subscribeToRouteTriggers(
        studentService: studentService,
        attendanceService: attendanceService,
        channelPrefix: 'owner_map_route',
        onRouteDataChanged: _reloadStudentsAndRoutes,
      );
    } catch (e) {
      debugPrint('Error inicializando mapa del dueño: $e');
    }
  }

  void _onTelemetryTick() {
    if (mounted) setState(() {});
  }

  Future<void> _reloadStudentsAndRoutes() async {
    if (!mounted) return;
    try {
      final studentService = context.read<StudentService>();
      final updatedStudents = await studentService.getAllStudents();
      if (!mounted) return;
      setState(() {
        _students = updatedStudents;
        _isRealtimeActive = true;
        if (_selectedStudent != null) {
          _selectedStudent = updatedStudents.firstWhere(
            (s) => s.id == _selectedStudent!.id,
            orElse: () => _selectedStudent!,
          );
        }
      });
      unawaited(_refreshAllBusRoutes(buses, updatedStudents));
    } catch (e) {
      debugPrint('Aviso recargando estudiantes en mapa dueño: $e');
    }
  }

  Future<void> _refreshAllBusRoutes(
    List<BusMock> activeBuses,
    List<StudentPassengerMock> allStudents,
  ) async {
    final nextRoutes = <String, List<LatLng>>{};
    final nextOptimized = <String, OptimizedBusRoute>{};

    for (final bus in activeBuses) {
      final optimized = await _routeOptimizer.buildOptimalRoute(
        bus: bus,
        students: allStudents,
      );
      nextOptimized[bus.code] = optimized;
      if (optimized.polylinePoints.length >= 2) {
        nextRoutes[bus.code] = optimized.polylinePoints;
      }
    }

    if (mounted) {
      setState(() {
        _busRoutes = nextRoutes;
        _optimizedRoutes = nextOptimized;
      });
      final selected = _selectedBus;
      if (selected != null && nextOptimized.containsKey(selected.code)) {
        _telemetryController?.updateRoute(
          nextOptimized[selected.code]!,
          preserveProgress: true,
        );
      }
    }
  }

  @override
  void dispose() {
    _busSubscription?.cancel();
    _telemetryController?.removeListener(_onTelemetryTick);
    _telemetryController?.dispose();
    unawaited(_unsubscribeRouteTriggers?.call() ?? Future<void>.value());
    _mapController.dispose();
    super.dispose();
  }

  void _centerOnBus(LatLng position, BusMock bus) {
    setState(() {
      _selectedBus = bus;
      _selectedStudent = null;
    });
    final opt = _optimizedRoutes[bus.code];
    if (opt != null) {
      _telemetryController?.updateRoute(opt, preserveProgress: false);
    }
    _mapController.move(position, 15.8);
  }

  void _selectStudentPin(StudentPassengerMock student) {
    setState(() => _selectedStudent = student);
    if (student.pickupLatitude != null && student.pickupLongitude != null) {
      _mapController.move(
        LatLng(student.pickupLatitude!, student.pickupLongitude!),
        16.2,
      );
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student.name} (${student.busCode}) • ${student.pickupAddress}'),
        backgroundColor: SmartColors.deepBlack,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final studentsWithCoords = _students
        .where((s) => s.pickupLatitude != null && s.pickupLongitude != null)
        .toList();
    final visibleBuses = buses.where((b) => _selectedBusCodes.contains(b.code)).toList();
    final visibleStudents = studentsWithCoords
        .where((s) => _selectedBusCodes.contains(s.busCode))
        .toList();
    final allSelected = buses.isNotEmpty && _selectedBusCodes.length == buses.length;

    final visibleSchools = <String, ({String name, LatLng point, Color color})>{};
    for (final bus in visibleBuses) {
      final opt = _optimizedRoutes[bus.code];
      if (opt != null) {
        final c = _colorForBusCode(bus.code);
        for (final sch in opt.orderedSchools) {
          visibleSchools.putIfAbsent(
            sch.name,
            () => (name: sch.name, point: sch.point, color: c),
          );
        }
      }
    }

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
                  initialCenter: AppConstants.penonomeCenter,
                  initialZoom: 15.0,
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
                      for (int i = 0; i < buses.length; i++)
                        if (_selectedBusCodes.contains(buses[i].code) &&
                            (_busRoutes[buses[i].code] ?? const []).length >= 2)
                          Polyline(
                            points: _busRoutes[buses[i].code]!,
                            color: _colorForBusCode(buses[i].code).withValues(alpha: 0.85),
                            strokeWidth: _selectedBus?.code == buses[i].code ? 5.5 : 4.0,
                          ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcadores de domicilios solo para los buses activos en el filtro
                      for (final student in visibleStudents)
                        Marker(
                          point: LatLng(student.pickupLatitude!, student.pickupLongitude!),
                          width: isMobile ? 32 : 140,
                          height: isMobile ? 32 : 52,
                          child: GestureDetector(
                            onTap: () => _selectStudentPin(student),
                            child: _StudentHomePin(
                              student: student,
                              busColor: _colorForBusCode(student.busCode),
                              isHighlighted: _selectedBus == null ||
                                  _selectedBus!.code == student.busCode,
                              isSelected: _selectedStudent?.id == student.id,
                              isMobile: isMobile,
                            ),
                          ),
                        ),
                      // Marcadores GPS solo de los autobuses activos en el filtro
                      for (int i = 0; i < buses.length; i++) ...[
                        if (_selectedBusCodes.contains(buses[i].code))
                          () {
                            final bus = buses[i];
                            final busColor = _colorForBusCode(bus.code);
                            final isSelected = _selectedBus?.code == bus.code;
                            final simActiveForSelected =
                                isSelected && (_telemetryController?.isPlaying ?? false);
                            final pos = simActiveForSelected
                                ? _telemetryController!.currentPosition
                                : (bus.latitude != null && bus.longitude != null)
                                    ? LatLng(bus.latitude!, bus.longitude!)
                                    : LatLng(
                                        AppConstants.penonomeCenter.latitude + (0.0015 * i),
                                        AppConstants.penonomeCenter.longitude + (0.0015 * i),
                                      );
                            return Marker(
                              point: pos,
                              width: 82,
                              height: 82,
                              child: GestureDetector(
                                onTap: () => _centerOnBus(pos, bus),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: _BusGpsMarker(
                                    code: bus.code,
                                    busColor: busColor,
                                    isSelected: isSelected,
                                  ),
                                ),
                              ),
                            );
                          }(),
                      ],
                      // Marcadores de los colegios cubiertos por los buses visibles
                      for (final sch in visibleSchools.values)
                        Marker(
                          point: sch.point,
                          width: 44,
                          height: 44,
                          child: Tooltip(
                            message: sch.name,
                            child: Container(
                              decoration: BoxDecoration(
                                color: SmartColors.smartGreen,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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
                                  decoration: BoxDecoration(
                                    color: _isRealtimeActive ? SmartColors.smartGreen : SmartColors.electricCyan,
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
                              _mapController.move(AppConstants.penonomeCenter, 15.0);
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
                      // Selector multi-selección de unidades flotante con color por autobús
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            NeumorphicBox(
                              key: const Key('bus_filter_all'),
                              isPill: true,
                              isDark: allSelected,
                              onTap: _toggleAllBusesFilter,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Text(
                                'Todos',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: allSelected
                                      ? SmartColors.electricCyan
                                      : SmartColors.deepBlack,
                                ),
                              ),
                            ),
                            if (buses.isNotEmpty) const SizedBox(width: 8),
                            for (int i = 0; i < buses.length; i++) ...[
                              () {
                                final bus = buses[i];
                                final busColor = _colorForBusCode(bus.code);
                                final isActive = _selectedBusCodes.contains(bus.code);
                                return NeumorphicBox(
                                  key: Key('bus_filter_chip_${bus.code}'),
                                  isPill: true,
                                  isDark: isActive,
                                  onTap: () {
                                    final targetPos = (bus.latitude != null && bus.longitude != null)
                                        ? LatLng(bus.latitude!, bus.longitude!)
                                        : LatLng(
                                            AppConstants.penonomeCenter.latitude + (0.0015 * i),
                                            AppConstants.penonomeCenter.longitude + (0.0015 * i),
                                          );
                                    _toggleBusFilter(bus, targetPos);
                                  },
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? busColor
                                              : busColor.withValues(alpha: 0.35),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        bus.code,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                          color: isActive
                                              ? Colors.white
                                              : SmartColors.smartGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }(),
                              if (i < buses.length - 1) const SizedBox(width: 8),
                            ],
                          ],
                        ),
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
                                  visibleBuses.isEmpty
                                      ? '0 UNIDADES VISIBLES'
                                      : visibleBuses.length == 1
                                          ? visibleBuses.first.code
                                          : '${visibleBuses.length} UNIDADES VISIBLES',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                                Text(
                                  visibleBuses.isEmpty
                                      ? 'Selecciona un bus en el filtro superior'
                                      : visibleBuses.length == 1
                                          ? visibleBuses.first.model
                                          : visibleBuses.map((b) => b.code).join(' • '),
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
                            value: _selectedBus?.driverName ?? 'Sin asignar',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: SmartColors.deepPetrol.withValues(alpha: 0.15),
                          ),
                          _TelemetryItem(
                            label: 'CUPOS',
                            value:
                                '${_selectedBus?.seatsOccupied ?? 0}/${_selectedBus?.capacity ?? 0}',
                          ),
                          Container(
                            width: 1,
                            height: 28,
                            color: SmartColors.deepPetrol.withValues(alpha: 0.15),
                          ),
                          _TelemetryItem(
                            label: 'VELOCIDAD',
                            value: (_telemetryController?.isPlaying ?? false)
                                ? '${_telemetryController!.currentSpeedKmH.round()} km/h'
                                : '${_selectedBus?.currentSpeedKmH ?? 0} km/h',
                          ),
                        ],
                      ),
                    ),
                    if (_selectedBus != null &&
                        _optimizedRoutes.containsKey(_selectedBus!.code)) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Próx: ${_telemetryController?.nextStopLabel ?? 'Ruta activa'} • '
                              'Colegios: ${_optimizedRoutes[_selectedBus!.code]!.orderedSchools.map((s) => s.name).join(', ')}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: SmartColors.deepPetrol,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () {
                              final ctrl = _telemetryController;
                              if (ctrl == null) return;
                              if (ctrl.isPlaying) {
                                ctrl.pause();
                              } else {
                                ctrl.start();
                              }
                            },
                            icon: Icon(
                              (_telemetryController?.isPlaying ?? false)
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              size: 18,
                              color: SmartColors.deepBlue,
                            ),
                            label: Text(
                              (_telemetryController?.isPlaying ?? false) ? 'PAUSAR' : 'SIMULAR',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
  final Color busColor;
  final bool isSelected;

  const _BusGpsMarker({
    required this.code,
    required this.busColor,
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
              color: isSelected ? busColor : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: SmartColors.neuSurface,
            shape: BoxShape.circle,
            border: Border.all(color: busColor, width: isSelected ? 2.5 : 1.8),
            boxShadow: [
              BoxShadow(
                color: busColor.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            color: busColor,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _StudentHomePin extends StatelessWidget {
  final StudentPassengerMock student;
  final Color busColor;
  final bool isHighlighted;
  final bool isSelected;
  final bool isMobile;

  const _StudentHomePin({
    required this.student,
    required this.busColor,
    required this.isHighlighted,
    required this.isSelected,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = isSelected
        ? SmartColors.electricCyan
        : (isHighlighted ? busColor : SmartColors.smartGray);

    if (isMobile) {
      return Tooltip(
        message: '${student.name} (${student.busCode}) • ${student.pickupAddress}',
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, size: 15, color: Colors.white),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: SmartColors.ghostWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: pinColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: SmartColors.deepBlack.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            student.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: SmartColors.deepBlack,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: pinColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.8),
          ),
          child: const Icon(Icons.home_rounded, size: 12, color: Colors.white),
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
