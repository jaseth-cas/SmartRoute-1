import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  void _toggleAbsence(StudentPassengerMock student) {
    final bool willBeAbsent = student.status != PassengerStatus.absent;
    MockData.reportAbsence(student.id, willBeAbsent);
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final defaultRoute = MockData.getDefaultStudentRoute();
    final defaultStop = MockData.getDefaultStudentStop();
    final student = MockData.getPrimaryStudent();
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
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
        body: ResponsiveContent.wide(
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
                                  '\$${student.monthlyFee.toInt()} COP',
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
                        child: _buildEtaCard(defaultRoute, defaultStop, student, isAbsent),
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
                            TransitLoadingScreen.open(
                              context,
                              targetRoute: '/map/${defaultRoute.code}/${defaultStop.stopCode}',
                              title: 'RASTREO SATELITAL EN VIVO',
                              subtitle: 'Sincronizando satélites GPS con la unidad Toyota HiAce TBX-492...',
                              badge: 'OPENSTREETMAP GPS',
                            );
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
    );
  }

  Widget _buildEtaCard(
    RouteMock? defaultRoute,
    StopMock? defaultStop,
    StudentPassengerMock student,
    bool isAbsent,
  ) {
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
                  defaultRoute?.name ?? 'Ruta Escolar Norte – Col. San José',
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

          // Contador Central: Número 5 gigante y texto MIN
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isAbsent ? '--' : '${defaultRoute?.etaMinutes ?? 5}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 68,
                  fontWeight: FontWeight.w900,
                  color: isAbsent ? SmartColors.smartGray : const Color(0xFF0F172A),
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

          // Pista hundida telemática animada (Animloader estilo Uiverse alexruix)
          _AnimatedTelemetryTrack(isAbsent: isAbsent),
          const SizedBox(height: 20),

          // Fila Inferior: Parada y Chip "EN CAMINO"
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
                        'Parada: ${student.pickupAddress}',
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
                        color: isAbsent ? SmartColors.primaryCrimson : const Color(0xFF00C9FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isAbsent ? SmartColors.primaryCrimson : const Color(0xFF00C9FF))
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isAbsent ? 'OMITIDO' : 'EN CAMINO',
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
  }

}

/// Pista hundida telemática animada inspirada en la cinemática de ondas del animloader (Uiverse.io alexruix):
/// Las cápsulas redondeadas oscilan dinámicamente con desfase sinusoidal continuo (staggered delay),
/// transmitiendo la pulsación viva de telemetría por satélite GPS en tiempo real.
class _AnimatedTelemetryTrack extends StatefulWidget {
  final bool isAbsent;

  const _AnimatedTelemetryTrack({required this.isAbsent});

  @override
  State<_AnimatedTelemetryTrack> createState() => _AnimatedTelemetryTrackState();
}

class _AnimatedTelemetryTrackState extends State<_AnimatedTelemetryTrack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF00C9FF);
    const inactiveColor = Color(0xFFCBD5E1);

    final List<double> baseHeights = [
      6.0,
      9.0,
      13.0,
      16.5,
      19.5,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
      22.0,
    ];

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5ECF2),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: baseHeights.asMap().entries.map((entry) {
              final index = entry.key;
              final baseH = entry.value;
              final isActive = index <= 8 && !widget.isAbsent;

              double currentH = baseH;
              double glowAlpha = 0.35;

              if (!widget.isAbsent) {
                // Cálculo de fase sinusoidal desfasada por cada índice (staggered delay)
                final phase = (_controller.value * 2 * math.pi) - (index * 0.40);
                final wave = (math.sin(phase) + 1.0) / 2.0;

                if (isActive) {
                  // Oscilación vertical activa tipo animloader entre 4px y baseHeight
                  const minH = 4.0;
                  currentH = minH + (baseH - minH) * (0.2 + 0.8 * wave);
                  glowAlpha = 0.20 + (0.45 * wave);
                } else {
                  // Suave onda de eco en las barras pendientes
                  const minH = 12.0;
                  currentH = minH + (baseH - minH) * (0.65 + 0.35 * wave);
                }
              } else {
                currentH = 5.0;
              }

              final color = isActive ? activeColor : inactiveColor;
              final isCircle = index == 0 && currentH <= 6.5;

              return Container(
                width: isCircle ? 5.5 : 7.0,
                height: currentH,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: glowAlpha),
                            blurRadius: 4.0 * (currentH / baseH),
                            spreadRadius: 0.3,
                          ),
                        ]
                      : null,
                ),
              );
            }).toList(),
          );
        },
      ),
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

