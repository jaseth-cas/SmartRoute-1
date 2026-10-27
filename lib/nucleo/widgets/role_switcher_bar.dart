import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/widgets/continuous_tabs.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

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

    final targetRoute = role == UserRole.student
        ? '/student_home'
        : role == UserRole.driver
            ? '/driver_home'
            : '/owner_home';

    final roleLabel = role == UserRole.student
        ? 'PADRE'
        : role == UserRole.driver
            ? 'CHOFER'
            : 'DUEÑO';

    TransitLoadingScreen.open(
      context,
      targetRoute: targetRoute,
      title: 'CAMBIANDO A PERFIL $roleLabel',
      subtitle: 'Sincronizando la unidad escolar Toyota HiAce (TBX-492)...',
      badge: 'CONMUTACIÓN DE PERFIL',
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ContinuousTabs<UserRole>(
          height: 44,
          selected: currentRole,
          onChanged: (role) => _onSelectRole(context, role),
          tabs: const [
            ContinuousTabItem(
              value: UserRole.student,
              label: 'PADRE',
              icon: Icons.family_restroom_rounded,
            ),
            ContinuousTabItem(
              value: UserRole.driver,
              label: 'CHOFER',
              icon: Icons.airline_seat_recline_normal_rounded,
            ),
            ContinuousTabItem(
              value: UserRole.owner,
              label: 'DUEÑO',
              icon: Icons.business_center_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
