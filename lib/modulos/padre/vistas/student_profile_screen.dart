import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/session_info_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'CUENTA // PERFIL TUTOR',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: SmartColors.deepBlack,
          ),
        ),
        backgroundColor: SmartColors.neuBackground,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: NeumorphicBox(
            padding: EdgeInsets.zero,
            isPill: true,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: SmartColors.deepBlack),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/student_home');
                }
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: NeumorphicBox(
              padding: EdgeInsets.zero,
              isPill: true,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, color: SmartColors.deepBlue, size: 18),
                onPressed: () => context.push('/edit_profile'),
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveContent.narrow(
        maxWidth: 580,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            const SizedBox(height: 10),
            // Avatar Neumórfico Esculpido
            NeumorphicBox(
              width: 100,
              height: 100,
              borderRadius: BorderRadius.circular(34),
              child: const Center(
                child: Icon(Icons.family_restroom_rounded, size: 48, color: SmartColors.deepBlue),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              session?.name ?? 'Carlos Gómez (Tutor)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
                color: SmartColors.deepBlack,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              session?.email ?? 'carlos.gomez@smartroute.com',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: SmartColors.smartGray,
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta de Datos de Usuario
            NeumorphicBox(
              padding: const EdgeInsets.all(22),
              borderRadius: BorderRadius.circular(26),
              child: Column(
                children: [
                  _ProfileInfoItem(
                    icon: Icons.verified_user_outlined,
                    label: 'ROL EN SISTEMA',
                    value: session?.role.displayName.toUpperCase() ?? 'PADRE / FAMILIA',
                    isMono: true,
                  ),
                  const Divider(height: 20),
                  const _ProfileInfoItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'CANAL DE ALERTAS',
                    value: 'PUSH ACTIVAS (100%)',
                    isMono: true,
                  ),
                  const Divider(height: 20),
                  const _ProfileInfoItem(
                    icon: Icons.alt_route_rounded,
                    label: 'RUTA ESCOLAR ASIGNADA',
                    value: 'Ruta Escolar Norte - Col. San José',
                  ),
                  const Divider(height: 20),
                  const _ProfileInfoItem(
                    icon: Icons.school_outlined,
                    label: 'COLEGIO DE DESTINO',
                    value: 'Colegio San José (Sede Principal)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const SessionInfoCard(),
            const SizedBox(height: 28),

            PrimaryButton(
              text: 'CERRAR SESIÓN',
              icon: Icons.logout_rounded,
              isCrimson: true,
              onPressed: () {
                sessionManager.logout();
                context.go('/login');
              },
            ),
            const SizedBox(height: 20),
            const InfoBanner(
              text: 'Perfil de demostración académica y validación de interfaces.',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    ),
  );
}
}

class _ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMono;

  const _ProfileInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SmartColors.deepBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: SmartColors.deepBlue, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: SmartColors.smartGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: isMono
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepBlack,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepBlack,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
