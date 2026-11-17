import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/supabase_client.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/widgets/user_options_bar.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  StudentPassengerMock? _student;
  BusMock? _bus;
  RouteMock? _route;
  StopMock? _primaryStop;
  bool _isLoading = true;
  StreamSubscription? _attendanceSub;
  StreamSubscription<StudentPassengerMock>? _locationSub;

  @override
  void initState() {
    super.initState();
    _locationSub = StudentService.locationUpdatesStream.listen((updated) {
      if (!mounted) return;
      if (_student == null || _student!.id == updated.id) {
        setState(() {
          _student = updated;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentData(silent: false);
      _setupRealtimeSubscription();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStudentData({bool silent = false}) async {
    if (!silent && _student == null && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final studentService = context.read<StudentService>();
      final busService = context.read<BusService>();
      final session = context.read<SessionManager>().currentSession;
      final userId = SupabaseConfig.client.auth.currentUser?.id ?? session?.userId;

      final student = await studentService.getPrimaryStudent(userId);
      if (student == null) {
        if (mounted) {
          setState(() {
            _student = null;
            _bus = null;
            _route = null;
            _primaryStop = null;
            _isLoading = false;
          });
        }
        return;
      }

      final details = await Future.wait([
        busService.getBusByCode(student.busCode),
        busService.getRouteByCode(student.busCode),
        busService.getStopsByBusCode(student.busCode),
      ]);

      final fetchedBus = details[0] as BusMock?;
      final fetchedRoute = details[1] as RouteMock?;
      final busStops = details[2] as List<StopMock>;
      final matchedStop = busStops
              .where((s) => s.stopCode == 'EST-${student.id}')
              .firstOrNull ??
          busStops.firstOrNull;

      if (mounted) {
        setState(() {
          _student = student;
          _bus = fetchedBus;
          _route = fetchedRoute;
          _primaryStop = matchedStop;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del estudiante: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final attendanceService = context.read<AttendanceService>();
      _attendanceSub = attendanceService.streamTodayAttendance().listen((_) {
        if (mounted) {
          _loadStudentData(silent: true);
        }
      });
    } catch (e) {
      debugPrint('Aviso en stream de asistencia: $e');
    }
  }

  Future<void> _toggleAbsence(StudentPassengerMock student) async {
    final bool willBeAbsent = student.status != PassengerStatus.absent;
    setState(() {
      _student = student.copyWith(
        status: willBeAbsent ? PassengerStatus.absent : PassengerStatus.waiting,
      );
    });
    try {
      final attendanceService = context.read<AttendanceService>();
      await attendanceService.reportAbsence(
        studentId: student.id,
        isAbsent: willBeAbsent,
      );
      await _loadStudentData(silent: true);
    } catch (e) {
      debugPrint('Aviso sincronizando ausencia en Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = _route;
    final defaultStop = _primaryStop;
    final student = _student;
    final isAbsent = student?.status == PassengerStatus.absent;
    final isOnboard = student?.status == PassengerStatus.onboard;
    final isDelivered = student?.status == PassengerStatus.delivered;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Row(
            children: [
              NeumorphicBox(
                width: 34,
                height: 34,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.all(4),
                child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Text(
                'SmartRoute',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: SmartColors.deepBlack,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          actions: const [
            UserAppBarActions(),
          ],
          backgroundColor: SmartColors.neuBackground,
          elevation: 0,
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/student_home',
          onNavigate: (route) => context.go(route),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: SmartColors.deepBlue))
            : student == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const EmptyState(
                            message: 'Sin estudiante vinculado',
                            subMessage:
                                'Configura el perfil de tu hijo(a) y su domicilio de recogida para activar el rastreo escolar.',
                            icon: Icons.child_care_rounded,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/edit_profile'),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('CONFIGURAR PERFIL Y DOMICILIO'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SmartColors.deepBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ResponsiveContent.wide(
          maxWidth: 1080,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado del Padre / Tutor con tarjeta esculpida
                NeumorphicBox(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.family_restroom_rounded, color: SmartColors.deepBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TUTOR // ${(session?.name ?? student.parentName).toUpperCase()}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: SmartColors.smartGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              student.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              '${student.schoolName} • ${student.busCode}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: SmartColors.deepBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusChip(text: isAbsent ? 'Ausente' : (isDelivered ? 'Entregado' : (isOnboard ? 'A bordo' : 'Esperando'))),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Distribución Fluida 2 Columnas (Tablet/Desktop) o 1 Columna (Móvil)
                ResponsiveTwoColumns(
                  breakpoint: 840,
                  spacing: 20,
                  // Columna Izquierda: Biometría, Inasistencias y Finanzas
                  left: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- TARJETA DE SEGURIDAD Y ABORDAJE BIOMÉTRICO (AI BOARDING) ---
                      NeumorphicBox(
                        padding: const EdgeInsets.all(22),
                        borderRadius: BorderRadius.circular(26),
                        isDark: isOnboard,
                        border: Border.all(
                          color: isAbsent
                              ? SmartColors.primaryCrimson.withValues(alpha: 0.3)
                              : (isOnboard ? SmartColors.vibrantCyan.withValues(alpha: 0.4) : SmartColors.vibrantCyan.withValues(alpha: 0.2)),
                          width: 1.5,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAbsent
                                        ? SmartColors.primaryCrimson.withValues(alpha: 0.15)
                                        : (isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue.withValues(alpha: 0.1)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isAbsent
                                        ? Icons.person_off_rounded
                                        : (isOnboard ? Icons.face_retouching_natural_rounded : Icons.directions_bus_rounded),
                                    color: isAbsent
                                        ? SmartColors.primaryCrimson
                                        : (isOnboard ? SmartColors.deepBlack : SmartColors.deepBlue),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isAbsent
                                            ? 'AUSENCIA CONFIRMADA'
                                            : (isOnboard ? 'ESTUDIANTE A BORDO' : 'EN ESPERA DE RECOGIDA'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15.5,
                                          letterSpacing: 0.4,
                                          color: isOnboard ? SmartColors.ghostWhite : SmartColors.deepBlack,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isAbsent
                                            ? 'El bus omitirá tu parada para optimizar la ruta'
                                            : (isOnboard
                                                ? 'Verificado por IA Facial a las ${student.lastBoardingTime ?? "07:14 AM"}'
                                                : 'El bus escolar se aproxima a tu domicilio'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: isOnboard ? Colors.white70 : SmartColors.smartGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                if (_bus != null) {
                                  TrustSafetyDialog.show(
                                    context,
                                    bus: _bus!,
                                    isOwnerView: false,
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isOnboard ? const Color(0xFF091622) : SmartColors.neuInset,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_rounded,
                                          color: isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isOnboard ? 'BIOMETRÍA FACIAL OK (99.8%)' : 'PROTOCOLO TRUST & SAFETY',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      student.busCode,
                                      style: GoogleFonts.jetBrainsMono(
                                        fontWeight: FontWeight.w900,
                                        color: isOnboard ? SmartColors.ghostWhite : SmartColors.deepBlack,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- BOTÓN INASISTENCIA (GESTIÓN DE CUPOS / AHORRO DE RUTA) ---
                      _AttendanceCard(
                        isAbsent: isAbsent,
                        onToggle: () => _toggleAbsence(student),
                      ),
                      const SizedBox(height: 16),

                        // Distribución Fluida 2 Columnas (Tablet/Desktop) o 1 Columna (Móvil)
                        ResponsiveTwoColumns(
                          breakpoint: 840,
                          spacing: 20,
                          // Columna Izquierda: Biometría, Inasistencias y Finanzas
                          left: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- TARJETA DE SEGURIDAD Y ABORDAJE BIOMÉTRICO (AI BOARDING) ---
                              NeumorphicBox(
                                padding: const EdgeInsets.all(22),
                                borderRadius: BorderRadius.circular(26),
                                isDark: isOnboard,
                                border: Border.all(
                                  color: isAbsent
                                      ? SmartColors.primaryCrimson.withValues(alpha: 0.3)
                                      : (isOnboard ? SmartColors.vibrantCyan.withValues(alpha: 0.4) : SmartColors.vibrantCyan.withValues(alpha: 0.2)),
                                  width: 1.5,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isAbsent
                                                ? SmartColors.primaryCrimson.withValues(alpha: 0.15)
                                                : (isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue.withValues(alpha: 0.1)),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isAbsent
                                                ? Icons.person_off_rounded
                                                : (isOnboard ? Icons.face_retouching_natural_rounded : Icons.directions_bus_rounded),
                                            color: isAbsent
                                                ? SmartColors.primaryCrimson
                                                : (isOnboard ? SmartColors.deepBlack : SmartColors.deepBlue),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isAbsent
                                                    ? 'AUSENCIA CONFIRMADA'
                                                    : (isOnboard ? 'ESTUDIANTE A BORDO' : 'EN ESPERA DE RECOGIDA'),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15.5,
                                                  letterSpacing: 0.4,
                                                  color: isOnboard ? SmartColors.ghostWhite : SmartColors.deepBlack,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isAbsent
                                                    ? 'El bus omitirá tu parada para optimizar la ruta'
                                                    : (isOnboard
                                                        ? 'Verificado por IA Facial a las ${student.lastBoardingTime ?? "07:14 AM"}'
                                                        : 'El bus escolar se aproxima a tu domicilio'),
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  color: isOnboard ? Colors.white70 : SmartColors.smartGray,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isOnboard ? const Color(0xFF091622) : SmartColors.neuInset,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.verified_rounded,
                                                color: isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isOnboard ? 'BIOMETRÍA FACIAL OK (99.8%)' : 'PROTOCOLO TRUST & SAFETY',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: isOnboard ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                                                ),
                                              ),
                                            ],
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              if (_bus != null) {
                                                TrustSafetyDialog.show(
                                                  context,
                                                  bus: _bus!,
                                                  isOwnerView: false,
                                                );
                                              }
                                            },
                                            child: Text(
                                              student.busCode,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontWeight: FontWeight.w900,
                                                color: isOnboard ? SmartColors.ghostWhite : SmartColors.deepBlack,
                                                fontSize: 12,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: SmartColors.deepBlack,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'AL DÍA',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: SmartColors.vibrantCyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cuota Octubre 2026:',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: SmartColors.smartGray),
                                ),
                                Text(
                                  '\$${student.monthlyFee.toInt()}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Columna Derecha: ETA, Visor Satelital e Información
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- ESTIMACIÓN DE LLEGADA (ETA) CON TRACK SATELITAL ---
                      SectionTitle(
                        text: 'Tiempo Estimado de Llegada',
                        subtext: 'TELEMETRÍA SATELITAL',
                      ),
                      GestureDetector(
                        onTap: () {
                          if (defaultRoute != null) {
                            context.push('/route_detail/${defaultRoute.code}');
                          }
                        },
                        child: _EtaProgressCard(
                          defaultRoute: defaultRoute,
                          defaultStop: defaultStop,
                          student: student,
                          isAbsent: isAbsent,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- MAPA EN VIVO DEL BUS ---
                      SectionTitle(
                        text: 'Rastreo Satelital en Mapa',
                        subtext: 'OPENSTREETMAP GPS',
                      ),
                      GestureDetector(
                        onTap: () {
                          final busCode = student.busCode;
                          final stopCode = defaultStop?.stopCode ?? 'EST-${student.id}';
                          TransitLoadingScreen.open(
                            context,
                            targetRoute: '/map/$busCode/$stopCode',
                            title: 'RASTREO SATELITAL EN VIVO',
                            subtitle:
                                'Sincronizando satélites GPS con ${_bus?.model ?? 'la unidad'} (${_bus?.plate ?? busCode})...',
                            badge: 'OPENSTREETMAP GPS',
                          );
                        },
                        child: NeumorphicBox(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          borderRadius: BorderRadius.circular(24),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: SmartColors.deepBlack,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.deepBlack.withValues(alpha: 0.25),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.map_rounded, color: SmartColors.vibrantCyan, size: 28),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'VISOR SATELITAL EN TIEMPO REAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sigue la unidad escolar parada por parada',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: SmartColors.smartGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const InfoBanner(
                        text: 'SmartRoute: Transporte Escolar Seguro con Reconocimiento Facial y Optimización de Ruta.',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Tarjeta de Tiempo Estimado de Llegada (ETA) con telemetría en tiempo real:
/// - Muestra el tiempo restante sincronizado con la cuenta regresiva.
/// - Barra de progreso lineal elegante con estilo Uiverse (track gris #BABABA,
///   indicador azul vibrante #0071E2, bordes redondeados y glow sutil).
/// - Llena progresivamente de 0% a 100% en un tiempo exacto de 10 minutos (600 segundos).
class _EtaProgressCard extends StatefulWidget {
  final RouteMock? defaultRoute;
  final StopMock? defaultStop;
  final StudentPassengerMock student;
  final bool isAbsent;

  const _EtaProgressCard({
    required this.defaultRoute,
    required this.defaultStop,
    required this.student,
    required this.isAbsent,
  });

  @override
  State<_EtaProgressCard> createState() => _EtaProgressCardState();
}

class _EtaProgressCardState extends State<_EtaProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;

  static const Duration _totalDuration = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _totalDuration,
    );

    if (!widget.isAbsent) {
      _progressController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _EtaProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAbsent != oldWidget.isAbsent) {
      if (widget.isAbsent) {
        _progressController.stop();
      } else {
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, _) {
        final double progress = _progressController.value;
        final bool isCompleted = progress >= 1.0;

        // Minutos restantes: inicia en 10 MIN y desciende progresivamente hasta 0 MIN
        final int remainingSeconds = ((1.0 - progress) * _totalDuration.inSeconds).ceil();
        final int remainingMinutes = (remainingSeconds / 60).ceil();

        final String etaDisplay = widget.isAbsent
            ? '--'
            : (isCompleted ? '0' : '$remainingMinutes');

        final String statusLabel = widget.isAbsent
            ? 'OMITIDO'
            : (isCompleted ? 'LLEGÓ' : 'EN CAMINO');

        final Color statusColor = widget.isAbsent
            ? SmartColors.primaryCrimson
            : (isCompleted ? const Color(0xFF10B981) : const Color(0xFF0071E2));

        return NeumorphicBox(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fila Superior: Icono de Bus en relieve suave, Título de la Ruta y Botón Chevron
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: SmartColors.ghostWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.neuLightShadow,
                          offset: const Offset(-2, -2),
                          blurRadius: 5,
                        ),
                        BoxShadow(
                          color: SmartColors.deepBlue.withValues(alpha: 0.08),
                          offset: const Offset(2, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF6B7C8E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.defaultRoute?.name ?? 'Ruta Escolar Norte – Col. San José',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: SmartColors.ghostWhite,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.neuLightShadow,
                          offset: const Offset(-2, -2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: SmartColors.deepBlue.withValues(alpha: 0.08),
                          offset: const Offset(2, 2.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF334155),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Contador Central: Número gigante y texto MIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    etaDisplay,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 68,
                      fontWeight: FontWeight.w900,
                      color: widget.isAbsent ? SmartColors.smartGray : const Color(0xFF0F172A),
                      letterSpacing: -2.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MIN',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: const Color(0xFF1E3A52),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Barra de carga lineal con llenado progresivo en 10 minutos (Estilo Uiverse)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6.0,
                    width: double.infinity,
                    color: const Color(0xFFBABABA), // Track gris #BABABA fiel a la referencia
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.isAbsent ? 0.0 : progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0071E2), // Azul vibrante #0071E2
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0071E2).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Fila Inferior: Parada y Chip 'EN CAMINO' / 'LLEGÓ'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF94A3B8),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.place_rounded,
                              color: Color(0xFF64748B),
                              size: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Parada: ${widget.student.pickupAddress}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5FA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFD3E4F0),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFF1E3A52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Panel interactivo de gestión de asistencia e inasistencia.
/// Soporta:
/// 1. Efecto hover interactivo en el botón de confirmación.
/// 2. Inversión animada de colores del panel completo al ser presionado:
///    El fondo blanco toma el color rojo del botón (#D32F2F) y las letras
///    cambian a blanco con relieve, y el botón se invierte a fondo blanco.
class _AttendanceCard extends StatefulWidget {
  final bool isAbsent;
  final VoidCallback onToggle;

  const _AttendanceCard({
    required this.isAbsent,
    required this.onToggle,
  });

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isAbsent = widget.isAbsent;

    final panelBg = isAbsent ? SmartColors.primaryCrimson : SmartColors.ghostWhite;
    final titleColor = isAbsent ? Colors.white : SmartColors.deepBlack;
    final subtitleColor = isAbsent ? Colors.white.withValues(alpha: 0.88) : SmartColors.smartGray;
    final iconBoxBg = isAbsent
        ? Colors.white.withValues(alpha: 0.20)
        : SmartColors.primaryCrimson.withValues(alpha: 0.12);
    final iconColor = isAbsent ? Colors.white : SmartColors.primaryCrimson;

    final btnBg = isAbsent ? Colors.white : SmartColors.primaryCrimson;
    final btnTextColor = isAbsent ? SmartColors.primaryCrimson : Colors.white;
    final btnText = isAbsent ? 'ASISTIRÁ' : 'NO ASISTE';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAbsent
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          if (isAbsent) ...[
            BoxShadow(
              color: SmartColors.primaryCrimson.withValues(alpha: 0.35),
              offset: const Offset(0, 6),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.18),
              offset: const Offset(0, -1),
              blurRadius: 2,
            ),
          ] else ...[
            BoxShadow(
              color: SmartColors.neuLightShadow,
              offset: const Offset(-3, -3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: SmartColors.deepBlue.withValues(alpha: 0.10),
              offset: const Offset(3, 5),
              blurRadius: 12,
            ),
          ],
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBoxBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAbsent ? Icons.event_busy_rounded : Icons.calendar_today_rounded,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: titleColor,
                  ),
                  child: Text(
                    isAbsent ? 'Ausencia notificada hoy' : '¿Tu hijo no asistirá hoy?',
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(
                    isAbsent
                        ? 'Notificaste para omitir tu parada.'
                        : 'Notifica para omitir tu parada.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedScale(
                scale: _isHovered ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: btnBg,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      if (isAbsent)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _isHovered ? 0.30 : 0.16),
                          offset: const Offset(0, 3),
                          blurRadius: _isHovered ? 10 : 6,
                          spreadRadius: _isHovered ? 1 : 0,
                        )
                      else
                        BoxShadow(
                          color: SmartColors.primaryCrimson.withValues(alpha: _isHovered ? 0.45 : 0.28),
                          offset: const Offset(0, 3),
                          blurRadius: _isHovered ? 12 : 8,
                          spreadRadius: _isHovered ? 1 : 0,
                        ),
                    ],
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                      letterSpacing: 0.6,
                      color: btnTextColor,
                    ),
                    child: Text(btnText),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

