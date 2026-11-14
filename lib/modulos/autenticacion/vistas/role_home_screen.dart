import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class RoleHomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToLogin;
  final Function(UserRole) onNavigateToRoleHome;

  const RoleHomeScreen({
    super.key,
    required this.onNavigateToLogin,
    required this.onNavigateToRoleHome,
  });

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: session == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        NeumorphicBox(
                          width: 80,
                          height: 80,
                          borderRadius: BorderRadius.circular(26),
                          child: const Icon(Icons.lock_clock_rounded, size: 36, color: SmartColors.primaryCrimson),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Sin Sesión Activa',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          text: 'IR AL LOGIN',
                          onPressed: onNavigateToLogin,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlack,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'SESSION GATE // SESIÓN ACTIVA',
                            style: GoogleFonts.jetBrainsMono(
                              color: SmartColors.vibrantCyan,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tarjeta Neumórfica de Usuario (estilo Quivox "COMPOUND 1")
                        NeumorphicBox(
                          padding: const EdgeInsets.all(24),
                          borderRadius: BorderRadius.circular(28),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: SmartColors.deepBlue.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  session.role == UserRole.student
                                      ? Icons.family_restroom_rounded
                                      : session.role == UserRole.driver
                                          ? Icons.airline_seat_recline_normal_rounded
                                          : Icons.domain_rounded,
                                  size: 36,
                                  color: SmartColors.deepBlue,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                session.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                  color: SmartColors.deepBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                decoration: BoxDecoration(
                                  color: SmartColors.vibrantCyan.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'ROL: ${session.role.displayName.toUpperCase()}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: SmartColors.deepBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Token técnico en caja inset
                              NeumorphicBox(
                                isInset: true,
                                padding: const EdgeInsets.all(12),
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.token_rounded, size: 16, color: SmartColors.deepBlue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'TOKEN // ${session.token}',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          color: SmartColors.smartGray,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        PrimaryButton(
                          text: 'ENTRAR AL PANEL PRINCIPAL',
                          icon: Icons.dashboard_rounded,
                          onPressed: () => onNavigateToRoleHome(session.role),
                        ),
                        const SizedBox(height: 14),

                        // Botón secundario para cambiar rol rápido
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                sessionManager.logout();
                                onNavigateToLogin();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: SmartColors.neuInset,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, size: 14, color: SmartColors.primaryCrimson),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CERRAR SESIÓN',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: SmartColors.primaryCrimson,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
