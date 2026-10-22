import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class PermissionGateScreen extends StatelessWidget {
  const PermissionGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 100, color: SmartColors.smartBlue),
              const SizedBox(height: 32),
              const Text(
                'Tu seguridad es nuestra\nmáxima prioridad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SmartColors.smartText),
              ),
              const SizedBox(height: 24),
              const Text(
                'Para protegerte a ti y a tu dispositivo, SmartRoute requiere acceso a tu ubicación GPS y notificaciones.\n\n'
                'Tus datos están encriptados, son 100% privados y jamás serán compartidos con terceros.\n\n'
                'Además, mantener tu GPS activo habilita nuestra función anti-pérdidas (Contacto SOS).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: SmartColors.smartGray, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartColors.smartBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // En un futuro aquí se pone: await Permission.location.request();
                    context.go('/login');
                  },
                  child: const Text('Aceptar y Activar Permisos', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
