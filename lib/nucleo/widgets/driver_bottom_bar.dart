import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barra de navegación inferior para el perfil de Conductor.
/// Implementa la animación física continua de pastilla deslizante inspirada en Framer Motion
/// (`layoutId="active-pill"`, stiffness: 380, damping: 30, mass: 0.9)
/// idéntica a la barra de conmutación del login.
class DriverBottomBar extends StatefulWidget {
  final String currentRoute;
  final Function(String) onNavigate;

  const DriverBottomBar({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  State<DriverBottomBar> createState() => _DriverBottomBarState();
}

class _DriverBottomBarState extends State<DriverBottomBar> {
  final List<Map<String, dynamic>> _items = const [
    {'route': '/driver_home', 'icon': Icons.directions_bus_rounded, 'label': 'Ruta'},
    {'route': '/driver_demand', 'icon': Icons.groups_rounded, 'label': 'Alumnos'},
    {'route': '/report_incident', 'icon': Icons.crisis_alert_rounded, 'label': 'Incidente'},
  ];

  static int _globalCurrentIndex = 0;
  static int? _globalFromIndex;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final targetIndex = _resolveIndex(widget.currentRoute);

    // Si venimos de un clic en otra pestaña de la barra, iniciamos la pastilla
    // en la posición previa y la deslizamos de inmediato al destino.
    if (_globalFromIndex != null && _globalFromIndex != targetIndex) {
      _selectedIndex = _globalFromIndex!;
      _globalFromIndex = null;
      _globalCurrentIndex = targetIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = targetIndex;
          });
        }
      });
    } else if (_globalCurrentIndex != targetIndex) {
      _selectedIndex = _globalCurrentIndex;
      _globalCurrentIndex = targetIndex;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = targetIndex;
          });
        }
      });
    } else {
      _selectedIndex = targetIndex;
      _globalCurrentIndex = targetIndex;
    }
  }

  @override
  void didUpdateWidget(covariant DriverBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      final newIndex = _resolveIndex(widget.currentRoute);
      if (newIndex != _selectedIndex) {
        _globalCurrentIndex = newIndex;
        setState(() {
          _selectedIndex = newIndex;
        });
      }
    }
  }

  int _resolveIndex(String route) {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i]['route'] == route) return i;
    }
    for (int i = 0; i < _items.length; i++) {
      final itemRoute = _items[i]['route'] as String;
      if (route.startsWith(itemRoute)) return i;
    }
    return 0;
  }

  void _onTabTapped(int index, String route) {
    if (_selectedIndex == index) return;

    // Preservar la posición de origen para que el deslizamiento continuo
    // se mantenga suave e ininterrumpido a través de la conmutación de pantalla
    final fromIndex = _selectedIndex;
    _globalFromIndex = fromIndex;
    _globalCurrentIndex = index;

    setState(() {
      _selectedIndex = index;
    });

    widget.onNavigate(route);
  }

  @override
  Widget build(BuildContext context) {
    const double barHeight = 58.0;
    const double inset = 4.5;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16, top: 4),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              height: barHeight,
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 14,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final tabCount = _items.length;
                  final availableWidth = totalWidth - (inset * 2);
                  final tabWidth = availableWidth / tabCount;
                  final pillLeft = inset + (_selectedIndex * tabWidth);
                  final isCompact = totalWidth < 360;

                  return Stack(
                    children: [
                      // Pastilla continua activa deslizante (Framer Motion spring)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
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

                      // Fila de opciones con textos e iconos siempre visibles
                      Row(
                        children: _items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final route = item['route'] as String;
                          final icon = item['icon'] as IconData;
                          final label = item['label'] as String;
                          final isSelected = _selectedIndex == index;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _onTabTapped(index, route),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                alignment: Alignment.center,
                                child: isCompact
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Icon(
                                              icon,
                                              key: ValueKey('$route-$isSelected'),
                                              size: 19,
                                              color: isSelected
                                                  ? const Color(0xFF01BAEF)
                                                  : const Color(0xFF62625D),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              letterSpacing: 0.2,
                                              color: isSelected
                                                  ? const Color(0xFFEDEDEC)
                                                  : const Color(0xFF62625D),
                                            ),
                                            child: Text(
                                              label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 200),
                                            child: Icon(
                                              icon,
                                              key: ValueKey('$route-$isSelected'),
                                              size: 19,
                                              color: isSelected
                                                  ? const Color(0xFF01BAEF)
                                                  : const Color(0xFF62625D),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeInOut,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              letterSpacing: 0.3,
                                              color: isSelected
                                                  ? const Color(0xFFEDEDEC)
                                                  : const Color(0xFF62625D),
                                            ),
                                            child: Text(
                                              label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
            ),
          ),
        ),
      ),
    );
  }
}
