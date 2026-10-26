import 'package:flutter/material.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Contenedor Neumórfico Esculpido & Minimalista
/// Inspirado en el lenguaje de diseño Quivox:
/// - Sombras duales suaves (luz blanca superior-izquierda + sombra oscura inferior-derecha)
/// - Bordes redondeados generosos o formato cápsula/pastilla
/// - Soporte para estado normal (relieve), hundido (inset), pastilla oscura (#040F16) o acentuado
class NeumorphicBox extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final dynamic borderRadius;
  final bool isPill;
  final bool isDark;
  final bool isInset;
  final bool isCyan;
  final bool isCrimson;
  final Color? color;
  final VoidCallback? onTap;
  final double elevation;
  final BoxBorder? border;

  const NeumorphicBox({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.isPill = false,
    this.isDark = false,
    this.isInset = false,
    this.isCyan = false,
    this.isCrimson = false,
    this.color,
    this.onTap,
    this.elevation = 1.0,
    this.border,
  });

  BorderRadius get _effectiveRadius {
    if (isPill) return BorderRadius.circular(999);
    if (borderRadius == null) return BorderRadius.circular(22);
    if (borderRadius is BorderRadius) return borderRadius as BorderRadius;
    if (borderRadius is num) return BorderRadius.circular((borderRadius as num).toDouble());
    return BorderRadius.circular(22);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = _effectiveRadius;

    Color surfaceColor;
    List<BoxShadow> shadows;

    if (isDark) {
      // Pastilla oscura de alto contraste (como "9:41 AM", "Acc" y perilla en Quivox)
      surfaceColor = color ?? SmartColors.deepBlack;
      shadows = [
        BoxShadow(
          color: SmartColors.deepBlack.withValues(alpha: 0.25 * elevation),
          offset: Offset(0, 4 * elevation),
          blurRadius: 10 * elevation,
        ),
      ];
    } else if (isCyan) {
      // Pastilla cian vibrante
      surfaceColor = color ?? SmartColors.vibrantCyan;
      shadows = [
        BoxShadow(
          color: SmartColors.vibrantCyan.withValues(alpha: 0.35 * elevation),
          offset: Offset(0, 4 * elevation),
          blurRadius: 12 * elevation,
        ),
      ];
    } else if (isCrimson) {
      // Pastilla carmesí de alerta
      surfaceColor = color ?? SmartColors.primaryCrimson;
      shadows = [
        BoxShadow(
          color: SmartColors.primaryCrimson.withValues(alpha: 0.35 * elevation),
          offset: Offset(0, 4 * elevation),
          blurRadius: 12 * elevation,
        ),
      ];
    } else if (isInset) {
      // Superficie hundida (para inputs de texto, contadores y ranuras)
      surfaceColor = color ?? SmartColors.neuInset;
      shadows = [
        BoxShadow(
          color: SmartColors.deepBlue.withValues(alpha: 0.04),
          offset: const Offset(1.5, 1.5),
          blurRadius: 3,
        ),
        const BoxShadow(
          color: Colors.white,
          offset: Offset(-1.5, -1.5),
          blurRadius: 3,
        ),
      ];
    } else {
      // Neumorfismo clásico en relieve
      surfaceColor = color ?? SmartColors.ghostWhite;
      shadows = [
        // Reflejo blanco superior izquierdo
        BoxShadow(
          color: SmartColors.neuLightShadow.withValues(alpha: 0.95),
          offset: Offset(-4 * elevation, -4 * elevation),
          blurRadius: 9 * elevation,
          spreadRadius: 1,
        ),
        // Sombra suave inferior derecha
        BoxShadow(
          color: SmartColors.deepBlue.withValues(alpha: 0.08 * elevation),
          offset: Offset(4 * elevation, 5 * elevation),
          blurRadius: 11 * elevation,
          spreadRadius: 0,
        ),
      ];
    }

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: effectiveRadius,
        boxShadow: shadows,
        border: border ??
            (isDark || isCyan || isCrimson
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1.0,
                  )),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: (isDark ? Colors.white12 : SmartColors.vibrantCyan.withValues(alpha: 0.1)),
          highlightColor: Colors.transparent,
          child: content,
        ),
      );
    }

    return content;
  }
}
