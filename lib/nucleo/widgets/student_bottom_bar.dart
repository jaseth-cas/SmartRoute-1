import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class StudentBottomBar extends StatelessWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const StudentBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'route': '/student_home', 'icon': Icons.home_rounded, 'label': 'Inicio'},
      {'route': '/routes', 'icon': Icons.alt_route_rounded, 'label': 'Rutas'},
      {'route': '/map', 'icon': Icons.explore_rounded, 'label': 'En Vivo'},
      {'route': '/eta', 'icon': Icons.timer_outlined, 'label': 'ETA'},
      {'route': '/notifications', 'icon': Icons.notifications_none_rounded, 'label': 'Alertas'},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 6),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: SmartColors.ghostWhite,
                borderRadius: BorderRadius.circular(999), // Cápsula completa Quivox
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
                  horizontal: isSelected ? 14 : 10,
                  vertical: 8,
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
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          color: SmartColors.ghostWhite,
                          fontSize: 12,
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
