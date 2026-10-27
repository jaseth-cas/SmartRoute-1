import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modelo de datos para un elemento dentro de [ContinuousTabs]
class ContinuousTabItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const ContinuousTabItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Componente de navegación continua tipo "Continuous Tabs"
/// Reproduce la animación física continua con pastilla deslizante inspirada en Framer Motion
/// (`layoutId="active-pill"`, stiffness: 380, damping: 30, mass: 0.9).
class ContinuousTabs<T> extends StatelessWidget {
  final List<ContinuousTabItem<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;
  final double inset;

  const ContinuousTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    this.height = 46,
    this.inset = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIndex = tabs.indexWhere((t) => t.value == selected);
    final activeIndex = selectedIndex >= 0 ? selectedIndex : 0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E5E9),
          width: 1.0,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFE9E9F2),
          ],
        ),
        boxShadow: [
          // Sombra exterior sutil
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
          // Reflejo blanco superior
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
          // Sombra inferior de relieve
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 1.5),
            blurRadius: 3,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabCount = tabs.length;
          final availableWidth = totalWidth - (inset * 2);
          final tabWidth = availableWidth / tabCount;
          final pillLeft = inset + (activeIndex * tabWidth);

          return Stack(
            children: [
              // Pastilla activa continua deslizante (Continuous Active Pill)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                // Curva cúbica calibrada que emula la física del resorte (spring stiffness: 380, damping: 30)
                curve: const Cubic(0.2, 0.95, 0.22, 1.05),
                left: pillLeft,
                top: inset,
                bottom: inset,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF252528),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF252528).withValues(alpha: 0.35),
                        offset: const Offset(0, 3),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Capa de pestañas interactivas y tipografía
              Row(
                children: tabs.map((tab) {
                  final isSelected = tab.value == selected;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(tab.value),
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (tab.icon != null) ...[
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  tab.icon,
                                  key: ValueKey('${tab.label}-$isSelected'),
                                  size: 13,
                                  color: isSelected
                                      ? const Color(0xFF01BAEF)
                                      : const Color(0xFF62625D),
                                ),
                              ),
                              const SizedBox(width: 5),
                            ],
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: isSelected
                                    ? const Color(0xFFEDEDEC)
                                    : const Color(0xFF62625D),
                              ),
                              child: Text(tab.label),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
