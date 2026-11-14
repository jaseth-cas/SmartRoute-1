import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class StatusChip extends StatelessWidget {
  final String text;
  final bool isDark;

  const StatusChip({super.key, required this.text, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color dotColor;

    final lowerText = text.toLowerCase();

    if (lowerText.contains("activa") ||
        lowerText.contains("en camino") ||
        lowerText.contains("calculado") ||
        lowerText.contains("estable") ||
        lowerText.contains("activo") ||
        lowerText.contains("en recorrido") ||
        lowerText.contains("al día") ||
        lowerText.contains("verificado")) {
      bgColor = SmartColors.vibrantCyan.withValues(alpha: 0.12);
      textColor = SmartColors.deepBlue;
      dotColor = SmartColors.vibrantCyan;
    } else if (lowerText.contains("inactiva") ||
        lowerText.contains("sin señal") ||
        lowerText.contains("detenido") ||
        lowerText.contains("inactivo") ||
        lowerText.contains("ausente") ||
        lowerText.contains("inasistencia") ||
        lowerText.contains("en mora") ||
        lowerText.contains("peligro")) {
      bgColor = SmartColors.primaryCrimson.withValues(alpha: 0.12);
      textColor = SmartColors.primaryCrimson;
      dotColor = SmartColors.primaryCrimson;
    } else if (lowerText.contains("calculando") ||
        lowerText.contains("actualizando") ||
        lowerText.contains("en espera") ||
        lowerText.contains("pendiente")) {
      bgColor = SmartColors.smartLightYellow;
      textColor = SmartColors.smartYellow;
      dotColor = SmartColors.smartYellow;
    } else {
      bgColor = SmartColors.neuInset;
      textColor = SmartColors.deepBlack;
      dotColor = SmartColors.deepBlue;
    }

    if (isDark) {
      bgColor = SmartColors.deepBlack;
      textColor = SmartColors.ghostWhite;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999), // Cápsula Quivox
        border: Border.all(
          color: dotColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
