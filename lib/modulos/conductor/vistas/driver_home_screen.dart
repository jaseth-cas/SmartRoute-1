import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/facial_boarding_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String routeStatus = "En recorrido";
  bool gpsActive = true;
  bool _isLoading = true;

  BusMock? _bus;
  List<StudentPassengerMock> _passengers = [];
  StreamSubscription? _attendanceSub;
  Timer? _gpsTimer;

  // Coordenadas base para la simulación de telemetría GPS
  double _currentLat = 9.9333;
  double _currentLng = -84.0772;
  int _telemetryStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDriverData();
      _setupRealtimeSubscription();
      _startGpsSimulation();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();

      final bus = await busService.getBusByCode('BUS-01') ??
          MockData.getBusByCode('BUS-01') ??
          MockData.buses.first;

      final students = await studentService.getStudentsByBus(bus.code);

      if (mounted) {
        setState(() {
          _bus = bus;
          _passengers = students;
          _currentLat = bus.latitude ?? 9.9333;
          _currentLng = bus.longitude ?? -84.0772;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del conductor: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

      // Generar pequeño desplazamiento realista por la ruta escolar
      _telemetryStep++;
      final latDelta = (_telemetryStep % 2 == 0 ? 0.0003 : -0.0002);
      final lngDelta = (_telemetryStep % 3 == 0 ? 0.0004 : -0.0001);

      _currentLat += latDelta;
      _currentLng += lngDelta;

      final busService = context.read<BusService>();
      busService.updateBusLocation(
        busCode: _bus!.code,
        latitude: _currentLat,
        longitude: _currentLng,
        speedKmH: 28 + (_telemetryStep % 12),
      );
    });
  }

  void _toggleGps() {
    setState(() {
      gpsActive = !gpsActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(gpsActive ? 'Transmisión GPS activada' : 'Transmisión GPS pausada'),
        duration: const Duration(seconds: 2),
        backgroundColor: gpsActive ? SmartColors.smartGreen : SmartColors.smartRed,
      ),
    );
  }

  void _openFacialScanner() {
    FacialBoardingDialog.show(
      context,
      onBoardingCompleted: () {
        _loadDriverData(silent: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final bus = _bus ?? MockData.getBusByCode('BUS-01') ?? MockData.buses.first;

    final passengers = _passengers.isNotEmpty ? _passengers : MockData.getPassengersByBus(bus.code);
    final absentStudents = passengers.where((p) => p.status == PassengerStatus.absent).toList();
    final onboardCount = passengers.where((p) => p.status == PassengerStatus.onboard).length;
    final waitingCount = passengers.where((p) => p.status == PassengerStatus.waiting).length;

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/driver_home',
        onNavigate: (route) => context.go(route),
      ),
      appBar: AppBar(
        title: const Text('SmartRoute Conductor', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Actualizar datos',
            icon: const Icon(Icons.refresh, color: SmartColors.smartBlue),
            onPressed: () => _loadDriverData(),
          ),
          IconButton(
            tooltip: 'Terminal Facial AI',
            icon: const Icon(Icons.face_retouching_natural, color: SmartColors.smartBlue),
            onPressed: _openFacialScanner,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SmartColors.smartBlue))
          : RefreshIndicator(
              onRefresh: () => _loadDriverData(),
              color: SmartColors.smartBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Perfil Conductor
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: SmartColors.smartLightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: SmartColors.smartBlue, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, ${session?.name ?? "Juan Pérez"}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: SmartColors.smartBlue),
                              ),
                              const Text('Ruta Escolar Activa • Conduce seguro', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sello Trust & Safety
                    SmartRouteCard(
                      color: SmartColors.smartLightGreen.withValues(alpha: 0.6),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: SmartColors.smartGreen, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Sello de Confianza SmartRoute', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartGreen)),
                                Text('Documentos, RTM y Antecedentes verificados para transporte escolar.', style: TextStyle(fontSize: 11, color: SmartColors.smartText)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alerta de Ausencias Reportadas (Recálculo Inteligente de Ruta - RF-11)
                    if (absentStudents.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notifications_active, color: Color(0xFFD97706), size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${absentStudents.length} ${absentStudents.length == 1 ? "Ausencia Notificada Hoy" : "Ausencias Notificadas Hoy"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${absentStudents.map((s) => '${s.name} (Parada #${s.order})').join(', ')} no asistirá. Las paradas se omitieron automáticamente de la ruta para optimizar tiempo y combustible.',
                                    style: TextStyle(fontSize: 11, color: Colors.brown.shade800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Información de Unidad y Recorrido
                    SmartRouteCard(
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.directions_bus, color: SmartColors.smartBlue),
                              SizedBox(width: 12),
                              Text('Información de la Unidad Escolar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _DriverDetailRow(icon: Icons.directions_bus, label: 'Unidad:', value: '${bus.code} (${bus.model})'),
                          _DriverDetailRow(icon: Icons.badge, label: 'Placa escolar:', value: bus.plate),
                          _DriverDetailRow(icon: Icons.alt_route, label: 'Ruta:', value: bus.routeName ?? 'Ruta Escolar Norte'),
                          _DriverDetailRow(icon: Icons.school, label: 'Colegio:', value: bus.schoolName ?? 'Colegio San José'),
                          _DriverDetailRow(icon: Icons.event_seat, label: 'Capacidad de ruta:', value: '${passengers.length}/${bus.capacity} Estudiantes'),
                          _DriverDetailRow(icon: Icons.people, label: 'Alumnos a bordo ahora:', value: '$onboardCount niños ($waitingCount en espera)'),
                          const SizedBox(height: 8),
                          const Divider(color: SmartColors.smartBorder, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.stacked_line_chart, color: SmartColors.smartGray, size: 16),
                                  SizedBox(width: 12),
                                  Text('Estado del recorrido:', style: TextStyle(fontSize: 13, color: SmartColors.smartGray)),
                                ],
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    routeStatus = routeStatus == "En recorrido" ? "Completada" : "En recorrido";
                                  });
                                  context.read<BusService>().updateBusStatus(
                                    busCode: bus.code,
                                    status: routeStatus,
                                  );
                                },
                                child: StatusChip(text: routeStatus),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: SmartColors.smartGray, size: 16),
                                  SizedBox(width: 12),
                                  Text('GPS en tiempo real:', style: TextStyle(fontSize: 13, color: SmartColors.smartGray)),
                                ],
                              ),
                              Row(
                                children: [
                                  StatusChip(text: gpsActive ? 'Transmitiendo' : 'Pausado'),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      gpsActive ? Icons.satellite_alt : Icons.satellite_alt_outlined,
                                      color: gpsActive ? SmartColors.smartGreen : SmartColors.smartGray,
                                      size: 20,
                                    ),
                                    onPressed: _toggleGps,
                                    tooltip: gpsActive ? 'Pausar GPS' : 'Activar GPS',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botones de acción operativos
                    ElevatedButton.icon(
                      onPressed: _openFacialScanner,
                      icon: const Icon(Icons.face, size: 22),
                      label: const Text('Terminal Facial AI (Abordaje)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartColors.smartBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/driver_demand'),
                      icon: const Icon(Icons.format_list_numbered, size: 20),
                      label: const Text('Ver Manifiesto de Pasajeros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SmartColors.smartBlue,
                        side: const BorderSide(color: SmartColors.smartBlue),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.update, color: SmartColors.smartGray, size: 14),
                        SizedBox(width: 8),
                        Text('Ubicación compartida con padres en vivo (PostgreSQL Realtime)', style: TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        sessionManager.logout();
                        context.go('/login');
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SmartColors.smartRed,
                        side: const BorderSide(color: SmartColors.smartBorder),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DriverDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DriverDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          Icon(icon, color: SmartColors.smartGray, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: SmartColors.smartGray)),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: SmartColors.smartText)),
        ],
      ),
    );
  }
}
