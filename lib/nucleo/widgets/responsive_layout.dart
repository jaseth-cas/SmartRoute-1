import 'package:flutter/material.dart';

/// Puntos de ruptura (Breakpoints) estándar para diseño responsivo
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 960;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}

/// Contenedor maestro responsivo que evita que las interfaces "Mobile First"
/// se estiren desproporcionadamente en monitores panorámicos (Desktop / Web),
/// manteniendo un centrado armónico, padding ergonómico y fluidez de escala.
class ResponsiveContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Para formularios o accesos (Login, Registro, Perfil)
  const ResponsiveContent.narrow({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding,
    this.alignment = Alignment.center,
  });

  /// Para dashboards y tablas con abundante información (OwnerHome, DriverDemand)
  const ResponsiveContent.wide({
    super.key,
    required this.child,
    this.maxWidth = 1140,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveWidth = constraints.maxWidth > maxWidth ? maxWidth : constraints.maxWidth;
        return Align(
          alignment: alignment,
          child: Container(
            width: effectiveWidth,
            height: constraints.maxHeight.isFinite ? constraints.maxHeight : null,
            padding: padding,
            child: child,
          ),
        );
      },
    );
  }
}

/// Componente que conmuta automáticamente entre 1 columna (Móvil)
/// y 2 columnas balanceadas (Tablet / Desktop) para evitar espacios vacíos.
class ResponsiveTwoColumns extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double breakpoint;
  final double spacing;

  const ResponsiveTwoColumns({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 768,
    this.spacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= breakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: spacing),
              Expanded(child: right),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }
      },
    );
  }
}
