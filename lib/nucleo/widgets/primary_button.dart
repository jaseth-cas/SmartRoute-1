import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool enabled;
  final bool isPill;
  final double height;
  final bool isSecondary;
  final bool isCrimson;
  final bool isDark;
  final bool isCyan;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor = SmartColors.deepBlack, // Por defecto pastilla negra Quivox
    this.foregroundColor = SmartColors.ghostWhite,
    this.enabled = true,
    this.isPill = true,
    this.height = 54,
    this.isSecondary = false,
    this.isCrimson = false,
    this.isDark = false,
    this.isCyan = false,
  });

  @override
  Widget build(BuildContext context) {
    Color effectiveBg = backgroundColor;
    Color effectiveFg = foregroundColor;

    if (isSecondary) {
      effectiveBg = SmartColors.neuSurface;
      effectiveFg = SmartColors.deepBlack;
    } else if (isCrimson) {
      effectiveBg = SmartColors.primaryCrimson;
      effectiveFg = Colors.white;
    } else if (isCyan) {
      effectiveBg = SmartColors.electricCyan;
      effectiveFg = SmartColors.deepBlack;
    } else if (isDark) {
      effectiveBg = SmartColors.deepBlack;
      effectiveFg = SmartColors.ghostWhite;
    }

    final radius = isPill ? BorderRadius.circular(999) : BorderRadius.circular(20);

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled
            ? [
                if (isSecondary) ...[
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-3, -3),
                    blurRadius: 7,
                  ),
                  BoxShadow(
                    color: SmartColors.deepBlue.withValues(alpha: 0.08),
                    offset: const Offset(3, 4),
                    blurRadius: 8,
                  ),
                ] else ...[
                  BoxShadow(
                    color: (effectiveBg == SmartColors.deepBlack
                            ? SmartColors.deepBlack
                            : effectiveBg)
                        .withValues(alpha: 0.25),
                    offset: const Offset(0, 5),
                    blurRadius: 12,
                  ),
                ],
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          disabledBackgroundColor: SmartColors.smartLightGray,
          disabledForegroundColor: SmartColors.smartGray,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: effectiveFg),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.3,
                color: effectiveFg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
