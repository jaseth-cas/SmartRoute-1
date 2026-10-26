import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

class NotificationCard extends StatelessWidget {
  final NotificationMock notification;
  final VoidCallback? onAction;
  final String actionLabel;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onAction,
    this.actionLabel = "ACC",
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'alert':
        icon = Icons.warning_amber_rounded;
        iconColor = SmartColors.primaryCrimson;
        break;
      case 'info':
        icon = Icons.near_me_rounded;
        iconColor = SmartColors.vibrantCyan;
        break;
      case 'system':
        icon = Icons.tune_rounded;
        iconColor = SmartColors.deepBlue;
        break;
      default:
        icon = Icons.notifications_none_rounded;
        iconColor = SmartColors.deepBlue;
    }

    return NeumorphicBox(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtítulo técnico minimalista (estilo "Notification Detailed Description")
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TELEMETRY NOTIF // ${notification.type.toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: SmartColors.smartGray,
                ),
              ),
              Text(
                notification.time,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SmartColors.deepBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono en cápsula neumórfica suave
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.deepBlack,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: SmartColors.smartGray,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Botón de acción pastilla negra Quivox (como "[Acc]")
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SmartColors.deepBlack,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: SmartColors.deepBlack.withValues(alpha: 0.25),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: SmartColors.ghostWhite,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
