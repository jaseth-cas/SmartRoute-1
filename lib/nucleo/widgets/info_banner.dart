import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color containerColor;
  final Color contentColor;
  final bool isWarning;

  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.containerColor = SmartColors.neuInset,
    this.contentColor = SmartColors.deepBlue,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveContent = isWarning ? SmartColors.primaryCrimson : contentColor;
    
    return NeumorphicBox(
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: effectiveContent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveContent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: SmartColors.deepBlack,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
