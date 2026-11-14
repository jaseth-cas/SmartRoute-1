import 'package:flutter/material.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Tarjeta Neumórfica principal para SmartRoute.
/// Reemplaza la tarjeta plana tradicional por una superficie esculpida
/// con doble sombra suave y bordes redondeados minimalistas.
class SmartRouteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool isDark;
  final bool isInset;

  const SmartRouteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.onTap,
    this.borderRadius,
    this.isDark = false,
    this.isInset = false,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicBox(
      color: color,
      padding: padding,
      onTap: onTap,
      borderRadius: borderRadius,
      isDark: isDark,
      isInset: isInset,
      child: child,
    );
  }
}
