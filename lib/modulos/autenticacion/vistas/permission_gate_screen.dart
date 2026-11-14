import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';

class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header técnico
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SmartColors.deepBlack,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'SECURITY GATE // PROTOCOL',
                      style: GoogleFonts.jetBrainsMono(
                        color: SmartColors.vibrantCyan,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'OMITIR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.smartGray,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),

              // Contenido central esculpido
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicBox(
                    width: 100,
                    height: 100,
                    borderRadius: BorderRadius.circular(32),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        size: 46,
                        color: SmartColors.deepBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Privacidad y Seguridad\nde Menores',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: SmartColors.deepBlack,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'SmartRoute utiliza telemetría cifrada punto a punto para proteger el trayecto escolar y validar el abordaje en tiempo real.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: SmartColors.smartGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Permisos en tarjetas esculpidas estilo Quivox ("MENU 1 / Menu 1 Subtext")
                  NeumorphicBox(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SmartColors.vibrantCyan.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.gps_fixed_rounded, color: SmartColors.vibrantCyan, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TELEMETRÍA GPS EN VIVO',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.4,
                                  color: SmartColors.deepBlack,
                                ),
                              ),
                              Text(
                                'Monitoreo de proximidad y cálculo exacto de ETA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: SmartColors.smartGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: SmartColors.deepBlue, size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeumorphicBox(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: SmartColors.deepBlue, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOTIFICACIONES DE ABORDAJE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.4,
                                  color: SmartColors.deepBlack,
                                ),
                              ),
                              Text(
                                'Avisos instantáneos de subida y bajada del bus',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: SmartColors.smartGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_rounded, color: SmartColors.deepBlue, size: 22),
                      ],
                    ),
                  ),
                ],
              ),

              // Botón de acción
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: PrimaryButton(
                  text: 'ACTIVAR Y CONTINUAR',
                  icon: Icons.lock_open_rounded,
                  onPressed: () => context.go('/login'),
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
}
