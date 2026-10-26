import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

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
    final passengers = _passengers.isNotEmpty ? _passengers : MockData.getPassengersByBus(bus.code);
    final onboardCount = passengers.where((p) => p.status == PassengerStatus.onboard).length;
    final absentCount = passengers.where((p) => p.status == PassengerStatus.absent).length;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'CABINA CONDUCIDA // TELEMETRÍA',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: SmartColors.deepBlack,
          ),
        ),
        backgroundColor: SmartColors.neuBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: gpsActive ? SmartColors.vibrantCyan : SmartColors.primaryCrimson,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'GPS ACTIVO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: SmartColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/driver_home',
        onNavigate: (route) => context.go(route),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: 1040,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Perfil Conductor Esculpido (ancho completo)
                NeumorphicBox(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.airline_seat_recline_normal_rounded, color: SmartColors.deepBlue, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONDUCTOR ASIGNADO',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: SmartColors.smartGray,
                              ),
                            ),
                            Text(
                              session?.name ?? "Juan Pérez",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: SmartColors.deepBlack,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${bus.code} • ${bus.routeName ?? "Ruta Escolar Norte"}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: SmartColors.deepBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(text: bus.status),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Distribución 2 columnas fluida en Tablet/Desktop, 1 columna en móvil
                ResponsiveTwoColumns(
                  breakpoint: 800,
                  spacing: 20,
                  left: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sello Trust & Safety
                      NeumorphicBox(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        borderRadius: BorderRadius.circular(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SmartColors.vibrantCyan.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_user_rounded, color: SmartColors.deepBlue, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SELLO TRUST & SAFETY CERTIFICADO',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  Text(
                                    'RTM, Antecedentes y Pólizas escolares al día',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: SmartColors.smartGray),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alerta de Ausencias Reportadas (Ahorro de Ruta)
                      if (absentCount > 0) ...[
                        NeumorphicBox(
                          isCrimson: false,
                          padding: const EdgeInsets.all(18),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: SmartColors.primaryCrimson.withValues(alpha: 0.4), width: 1.5),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: SmartColors.primaryCrimson.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_active_rounded, color: SmartColors.primaryCrimson, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$absentCount AUSENCIA NOTIFICADA HOY',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                        letterSpacing: 0.4,
                                        color: SmartColors.primaryCrimson,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Parada omitida automáticamente. Trayecto optimizado (-10 min).',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: SmartColors.smartGray),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Próxima Parada
                      NeumorphicBox(
                        padding: const EdgeInsets.all(18),
                        borderRadius: BorderRadius.circular(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRÓXIMA PARADA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: SmartColors.smartGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Colegio San José - Puerta 1',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Calle 127 # 45-20 • 2 Estudiantes esperan',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: SmartColors.deepBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Métricas de Pasajeros Quivox ("12/34", "10")
                      Row(
                        children: [
                          Expanded(
                            child: NeumorphicBox(
                              padding: const EdgeInsets.all(18),
                              borderRadius: BorderRadius.circular(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'A BORDO AHORA',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: SmartColors.smartGray),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '$onboardCount',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  Text(
                                    'ALUMNOS CONFIRMADOS',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: SmartColors.deepBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: NeumorphicBox(
                              padding: const EdgeInsets.all(18),
                              borderRadius: BorderRadius.circular(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OCUPACIÓN DE CUPOS',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: SmartColors.smartGray),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${bus.seatsOccupied}/${bus.capacity}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  Text(
                                    'ASIENTOS REGISTRADOS',
                                    style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: SmartColors.deepBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Botón de Terminal Facial AI
                      PrimaryButton(
                        text: 'TERMINAL FACIAL AI (ABORDAJE)',
                        icon: Icons.face_retouching_natural_rounded,
                        onPressed: _openFacialScanner,
                      ),
                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () => context.go('/driver_demand'),
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: SmartColors.neuInset,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.format_list_numbered_rounded, color: SmartColors.deepBlue, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'VER MANIFIESTO DE ESTUDIANTES',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.8,
                                  color: SmartColors.deepBlack,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Cerrar Sesión centrado
                Center(
                  child: GestureDetector(
                    onTap: () {
                      sessionManager.logout();
                      context.go('/login');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(
                        'CERRAR SESIÓN',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: SmartColors.primaryCrimson,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
