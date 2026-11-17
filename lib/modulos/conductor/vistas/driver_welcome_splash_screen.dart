import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Pantalla 1 del nuevo flujo del conductor:
/// Splash de Bienvenida personalizado con el nombre del conductor y mensaje positivo.
class DriverWelcomeSplashScreen extends StatefulWidget {
  const DriverWelcomeSplashScreen({super.key});

  @override
  State<DriverWelcomeSplashScreen> createState() => _DriverWelcomeSplashScreenState();
}

class _DriverWelcomeSplashScreenState extends State<DriverWelcomeSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoTransitionTimer;
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();

    // Barra de progreso animada de 3.5 segundos
    const totalMs = 3500;
    const intervalMs = 50;
    int elapsedMs = 0;

    _progressTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsedMs += intervalMs;
      if (mounted) {
        setState(() {
          _progress = (elapsedMs / totalMs).clamp(0.0, 1.0);
        });
      }
      if (elapsedMs >= totalMs) {
        timer.cancel();
      }
    });

    // Transición automática al cabo de 3.8 segundos
    _autoTransitionTimer = Timer(const Duration(milliseconds: 3800), () {
      _proceedToCardSorting();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _autoTransitionTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _proceedToCardSorting() {
    _autoTransitionTimer?.cancel();
    _progressTimer?.cancel();
    if (mounted) {
      context.go('/driver_card_sorting');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final driverName = (session != null && session.name.trim().isNotEmpty)
        ? session.name
        : 'Juan Pérez';
    final firstName = driverName.split(' ').isNotEmpty ? driverName.split(' ').first : 'Juan';

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge Superior de Sistema
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: SmartColors.deepBlue.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: SmartColors.smartGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SMARTROUTE OS // PENONOMÉ',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: SmartColors.deepBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tarjeta Principal de Bienvenida Neumórfica
                      NeumorphicBox(
                        padding: const EdgeInsets.all(28),
                        borderRadius: BorderRadius.circular(32),
                        child: Column(
                          children: [
                            // Avatar del Conductor con Anillo Activo
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 106,
                                  height: 106,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: SmartColors.neuInset,
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.neuDarkShadow,
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      const BoxShadow(
                                        color: SmartColors.neuLightShadow,
                                        offset: Offset(-4, -4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [SmartColors.deepBlue, SmartColors.deepBlack],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: SmartColors.vibrantCyan,
                                      width: 2.2,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.directions_bus_filled_rounded,
                                      size: 42,
                                      color: SmartColors.vibrantCyan,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: SmartColors.smartGreen,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Píldora de Rol de Conductor
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartColors.neuInset,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'CONDUCTOR ASIGNADO • SMARTROUTE',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: SmartColors.smartGray,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Saludo con Nombre
                            Text(
                              '¡Hola, $firstName!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: SmartColors.deepBlack,
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              driverName,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: SmartColors.deepBlue,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // Mensaje Positivo e Inspirador
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: SmartColors.neuInset.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: SmartColors.neuBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.favorite_rounded,
                                    color: SmartColors.primaryCrimson,
                                    size: 20,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '“Cada viaje es una promesa de seguridad para las familias de Penonomé. Tu dedicación, paciencia y puntualidad hacen posible el futuro de nuestros estudiantes. ¡Excelente inicio de ruta!”',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: SmartColors.deepBlack.withValues(alpha: 0.82),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Métricas rápidas de la Jornada
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.groups_rounded,
                                    title: '4 ALUMNOS',
                                    subtitle: 'Asistencias hoy',
                                    iconColor: SmartColors.deepBlue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.event_busy_rounded,
                                    title: '1 AUSENCIA',
                                    subtitle: 'Omitida (-10 min)',
                                    iconColor: SmartColors.primaryCrimson,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    icon: Icons.school_rounded,
                                    title: 'COL. SAN JOSÉ',
                                    subtitle: 'Destino final',
                                    iconColor: SmartColors.smartGreen,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Indicador de Progreso Suave
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor: SmartColors.neuInset,
                                valueColor: const AlwaysStoppedAnimation<Color>(SmartColors.vibrantCyan),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Cargando estudiantes y preparando Card Sorting...',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: SmartColors.smartGray,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Botón para avanzar inmediatamente
                      NeumorphicBox(
                        onTap: _proceedToCardSorting,
                        isDark: true,
                        isPill: true,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ORGANIZAR PARADAS DE HOY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: SmartColors.vibrantCyan,
                              size: 18,
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
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: SmartColors.neuInset,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: SmartColors.deepBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: SmartColors.smartGray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

