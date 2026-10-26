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
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  StudentPassengerMock? _student;
  BusMock? _bus;
  bool _isLoading = true;
  StreamSubscription? _attendanceSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentData();
      _setupRealtimeSubscription();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStudentData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final studentService = context.read<StudentService>();
      final busService = context.read<BusService>();
      final sessionManager = context.read<SessionManager>();
      final session = sessionManager.currentSession;

      // Consultar estudiantes asociados al autobús o tutor
      final students = await studentService.getStudentsByBus('BUS-01');

      StudentPassengerMock? matchedStudent;
      if (session != null && session.userId.isNotEmpty) {
        matchedStudent = students.cast<StudentPassengerMock?>().firstWhere(
              (s) => s != null && (s.parentName.toLowerCase().contains(session.name.toLowerCase()) ||
                  session.name.toLowerCase().contains(s.parentName.toLowerCase())),
              orElse: () => null,
            );
      }

      final student = matchedStudent ?? (students.isNotEmpty ? students.first : MockData.getPrimaryStudent());
      final bus = await busService.getBusByCode(student.busCode) ?? MockData.getBusByCode(student.busCode);

      if (mounted) {
        setState(() {
          _student = student;
          _bus = bus;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos del estudiante: $e');
      if (mounted) {
        setState(() {
          _student = MockData.getPrimaryStudent();
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

  void _toggleAbsence(StudentPassengerMock student) {
    final bool willBeAbsent = student.status != PassengerStatus.absent;

    if (willBeAbsent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: SmartColors.ghostWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'NOTIFICAR AUSENCIA',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: SmartColors.primaryCrimson,
              letterSpacing: 1.0,
            ),
          ),
          content: Text(
            '¿Confirmas que ${student.name} no tomará el transporte escolar hoy? La ruta del autobús se actualizará en tiempo real omitiendo tu parada.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: SmartColors.deepBlack,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: SmartColors.smartGray,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final attendanceService = context.read<AttendanceService>();
                  await attendanceService.reportAbsence(
                    studentId: student.id,
                    isAbsent: true,
                  );
                } catch (e) {
                  debugPrint('Aviso reportando ausencia a Supabase: $e');
                }
                MockData.reportAbsence(student.id, true);
                await _loadStudentData(silent: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ausencia registrada. Ruta del transportista optimizada.'),
                      backgroundColor: SmartColors.primaryCrimson,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: SmartColors.primaryCrimson,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'CONFIRMAR AUSENCIA',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      () async {
        try {
          final attendanceService = context.read<AttendanceService>();
          await attendanceService.reportAbsence(
            studentId: student.id,
            isAbsent: false,
          );
        } catch (e) {
          debugPrint('Aviso reactivando asistencia: $e');
        }
        MockData.reportAbsence(student.id, false);
        await _loadStudentData(silent: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha reactivado la recogida escolar de hoy.'),
              backgroundColor: SmartColors.vibrantCyan,
            ),
          );
        }
      }();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = MockData.getDefaultStudentRoute();
    final defaultStop = MockData.getDefaultStudentStop();
    final student = _student ?? MockData.getPrimaryStudent();
    final isAbsent = student.status == PassengerStatus.absent;
    final isOnboard = student.status == PassengerStatus.onboard;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Row(
            children: [
              NeumorphicBox(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.all(4),
                child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SmartRoute',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      color: SmartColors.deepBlack,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'PORTAL FAMILIA // EN VIVO',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      color: SmartColors.deepBlue,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  tooltip: 'Actualizar datos',
                  icon: const Icon(Icons.refresh_rounded, color: SmartColors.deepBlue, size: 20),
                  onPressed: () => _loadStudentData(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  icon: const Icon(Icons.person_outline_rounded, color: SmartColors.deepBlue, size: 20),
                  onPressed: () => context.push('/student_profile'),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  icon: const Badge(
                    backgroundColor: SmartColors.primaryCrimson,
                    child: Icon(Icons.notifications_none_rounded, color: SmartColors.deepBlack, size: 20),
                  ),
                  onPressed: () => context.go('/notifications'),
                ),
              ),
            ),
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
            : RefreshIndicator(
                onRefresh: () => _loadStudentData(),
                color: SmartColors.deepBlue,
                child: ResponsiveContent.wide(
                  maxWidth: 1080,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                      'TUTOR // ${session?.name.toUpperCase() ?? "CARLOS GÓMEZ"}',
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
                              StatusChip(text: isAbsent ? 'Ausente' : (isOnboard ? 'A bordo' : 'Esperando')),
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
                              ),
                              const SizedBox(height: 16),

                              // --- BOTÓN INASISTENCIA (GESTIÓN DE CUPOS / AHORRO DE RUTA) ---
                              NeumorphicBox(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                borderRadius: BorderRadius.circular(22),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isAbsent
                                            ? SmartColors.vibrantCyan.withValues(alpha: 0.15)
                                            : SmartColors.primaryCrimson.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isAbsent ? Icons.event_available_rounded : Icons.event_busy_rounded,
                                        color: isAbsent ? SmartColors.deepBlue : SmartColors.primaryCrimson,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAbsent ? '¿Mateo sí asistirá hoy?' : '¿Tu hijo no asistirá hoy?',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13.5,
                                              color: SmartColors.deepBlack,
                                            ),
                                          ),
                                          Text(
                                            isAbsent ? 'Reactivar recogida para hoy.' : 'Notifica para omitir tu parada.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: SmartColors.smartGray,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _toggleAbsence(student),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: isAbsent ? SmartColors.deepBlack : SmartColors.primaryCrimson,
                                          borderRadius: BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isAbsent ? SmartColors.deepBlack : SmartColors.primaryCrimson)
                                                  .withValues(alpha: 0.25),
                                              offset: const Offset(0, 3),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          isAbsent ? 'REACTIVAR' : 'NO ASISTE',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                            letterSpacing: 0.6,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // --- FINANZAS / ESTADO DE MENSUALIDAD ESCOLAR ---
                              NeumorphicBox(
                                isInset: true,
                                padding: const EdgeInsets.all(18),
                                borderRadius: BorderRadius.circular(22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.account_balance_wallet_outlined, color: SmartColors.deepBlue, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'SUSCRIPCIÓN // CUPO MENSUAL',
                                              style: GoogleFonts.jetBrainsMono(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 11,
                                                letterSpacing: 0.8,
                                                color: SmartColors.deepBlack,
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
                                            student.paymentStatus.toUpperCase(),
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
                                          'Cuota Mensual Escolar:',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: SmartColors.smartGray),
                                        ),
                                        Text(
                                          '\$${student.monthlyFee.toInt()} USD',
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
                              // --- ESTIMACIÓN DE LLEGADA (ETA) CON DIAL QUIVOX ---
                              SectionTitle(
                                text: 'Tiempo Estimado de Llegada',
                                subtext: 'TELEMETRÍA SATELITAL',
                                trailing: Text(
                                  defaultRoute?.code ?? "R-UB",
                                  style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w700, color: SmartColors.deepBlue),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (defaultRoute != null) {
                                    context.push('/route_detail/${defaultRoute.code}');
                                  }
                                },
                                child: NeumorphicBox(
                                  padding: const EdgeInsets.all(22),
                                  borderRadius: BorderRadius.circular(26),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _bus?.routeName ?? defaultRoute?.name ?? 'Ruta Escolar Norte',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: SmartColors.deepBlack,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: SmartColors.smartGray),
                                        ],
                                      ),
                                      const SizedBox(height: 20),

                                      // Contador de minutos estilo Quivox
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            isAbsent ? '--' : '${defaultRoute?.etaMinutes ?? 5}',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 62,
                                              fontWeight: FontWeight.w900,
                                              color: isAbsent ? SmartColors.smartGray : SmartColors.deepBlack,
                                              letterSpacing: -2.0,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'MIN',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: SmartColors.deepBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Regla de marcas métricas
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: List.generate(15, (index) {
                                          final isCenter = index == 7;
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 3),
                                            width: 2,
                                            height: isCenter ? 22 : (index % 2 == 0 ? 14 : 8),
                                            color: isCenter
                                                ? SmartColors.vibrantCyan
                                                : SmartColors.smartGray.withValues(alpha: 0.3),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Parada: ${student.pickupAddress}',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: SmartColors.smartGray),
                                          ),
                                          StatusChip(text: isAbsent ? 'Omitido' : 'En camino'),
                                        ],
                                      ),
                                    ],
                                  ),
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
                                  if (defaultRoute != null && defaultStop != null) {
                                    context.push('/map/${defaultRoute.code}/${defaultStop.stopCode}');
                                  }
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
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
