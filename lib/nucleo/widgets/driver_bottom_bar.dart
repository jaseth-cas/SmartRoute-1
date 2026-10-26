import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class DriverBottomBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const DriverBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'route': '/driver_home', 'icon': Icons.directions_bus_rounded, 'label': 'Ruta'},
      {'route': '/driver_demand', 'icon': Icons.groups_rounded, 'label': 'Alumnos'},
      {'route': '/report_incident', 'icon': Icons.crisis_alert_rounded, 'label': 'Incidente'},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 6),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: SmartColors.ghostWhite,
                borderRadius: BorderRadius.circular(999), // Cápsula Quivox
                boxShadow: [
                  BoxShadow(
                    color: SmartColors.neuLightShadow,
                    offset: const Offset(-3, -3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
            BoxShadow(
              color: SmartColors.deepBlue.withValues(alpha: 0.12),
              offset: const Offset(3, 5),
              blurRadius: 12,
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final route = item['route'] as String;
            final icon = item['icon'] as IconData;
            final label = item['label'] as String;
            final isSelected = currentRoute == route;

            return GestureDetector(
              onTap: () => onNavigate(route),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 18 : 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? SmartColors.deepBlack : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: SmartColors.deepBlack.withValues(alpha: 0.25),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected ? SmartColors.vibrantCyan : SmartColors.smartGray,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          color: SmartColors.ghostWhite,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
            ),
          ),
        ),
      ),
    ),
  );
}
}
