import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class SessionInfoCard extends StatelessWidget {
  const SessionInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SmartColors.smartLightGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SmartColors.smartGreen.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user, color: SmartColors.smartGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Rol actual: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text(
                      session?.role.name.toUpperCase() ?? 'NONE',
                      style: const TextStyle(fontSize: 11, color: SmartColors.smartGreen, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  'JWT simulado: ${session?.token ?? ''}',
                  style: const TextStyle(fontSize: 10, color: SmartColors.smartGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
