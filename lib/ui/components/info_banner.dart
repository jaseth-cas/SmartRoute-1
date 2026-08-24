import 'package:flutter/material.dart';
import '../theme/colors.dart';

class InfoBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color containerColor;
  final Color contentColor;

  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info,
    this.containerColor = SmartColors.smartLightBlue,
    this.contentColor = SmartColors.smartBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: contentColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: contentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: contentColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
