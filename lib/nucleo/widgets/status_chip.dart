import 'package:flutter/material.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class StatusChip extends StatelessWidget {
  final String text;

  const StatusChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    final lowerText = text.toLowerCase();

    if (lowerText.contains("activa") ||
        lowerText.contains("en camino") ||
        lowerText.contains("calculado") ||
        lowerText.contains("estable") ||
        lowerText.contains("activo")) {
      bgColor = SmartColors.smartLightGreen;
      textColor = SmartColors.smartGreen;
    } else if (lowerText.contains("inactiva") ||
        lowerText.contains("sin señal") ||
        lowerText.contains("detenido") ||
        lowerText.contains("inactivo")) {
      bgColor = SmartColors.smartLightRed;
      textColor = SmartColors.smartRed;
    } else if (lowerText.contains("calculando") ||
        lowerText.contains("actualizando")) {
      bgColor = const Color(0xFFFFF7ED);
      textColor = SmartColors.smartYellow;
    } else {
      bgColor = SmartColors.smartLightBlue;
      textColor = SmartColors.smartBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
