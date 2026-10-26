import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Barra de conmutación rápida de perfiles escolares (Padre / Chofer / Dueño)
/// Permite alternar instantáneamente entre los 3 paneles internos del sistema
class RoleSwitcherBar extends StatelessWidget {
  final UserRole currentRole;

  const RoleSwitcherBar({
    super.key,
    required this.currentRole,
  });

  void _onSelectRole(BuildContext context, UserRole role) {
    if (role == currentRole) return;
    final sessionManager = context.read<SessionManager>();
    sessionManager.switchRole(role);

    switch (role) {
      case UserRole.student:
        context.go('/student_home');
        break;
      case UserRole.driver:
        context.go('/driver_home');
        break;
      case UserRole.owner:
        context.go('/owner_home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: NeumorphicBox(
          isInset: true,
          padding: const EdgeInsets.all(4),
          borderRadius: BorderRadius.circular(999),
          child: Row(
            children: [
              _buildRoleItem(context, UserRole.student, 'PADRE', Icons.family_restroom_rounded),
              _buildRoleItem(context, UserRole.driver, 'CHOFER', Icons.airline_seat_recline_normal_rounded),
              _buildRoleItem(context, UserRole.owner, 'DUEÑO', Icons.business_center_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleItem(BuildContext context, UserRole role, String label, IconData icon) {
    final isSelected = currentRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onSelectRole(context, role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? SmartColors.deepBlack : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: SmartColors.deepBlack.withValues(alpha: 0.25),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? SmartColors.vibrantCyan : SmartColors.smartGray,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isSelected ? SmartColors.ghostWhite : SmartColors.smartGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
