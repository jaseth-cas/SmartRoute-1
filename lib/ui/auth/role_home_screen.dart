import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/auth/session_manager.dart';
import '../../data/models/models.dart';
import '../components/primary_button.dart';
import '../theme/colors.dart';

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
      backgroundColor: SmartColors.smartBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: session == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No hay sesión activa',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Ir al Login',
                      onPressed: onNavigateToLogin,
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¡Bienvenido!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: SmartColors.smartBlue,
                      ),
                    ),
                    Text(
                      session.name,
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      'Rol: ${session.role.displayName}',
                      style: TextStyle(
                        fontSize: 16,
                        color: SmartColors.smartDarkBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: SmartColors.smartLightBlue,
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'JWT Simulado:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              session.token,
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: 'Entrar al Panel',
                      onPressed: () => onNavigateToRoleHome(session.role),
                    ),
                    TextButton(
                      onPressed: () {
                        sessionManager.logout();
                        onNavigateToLogin();
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
