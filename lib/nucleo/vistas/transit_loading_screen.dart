import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/bus_transit_loader.dart';

/// Pantalla de carga telemática rediseñada fielmente según la referencia visual:
/// - Píldora superior oscura: "• AUTENTICACIÓN TRANSIT OS".
/// - Subtítulo sutil en tono slate.
/// - Tarjeta blanca central con esquinas redondeadas que aloja la escena animada del
///   autobús colegial Toyota HiAce ("COLEGIAL") iluminado por el poste de luz urbano.
/// - Barra de progreso cian y porcentaje en tiempo real.
class TransitLoadingScreen extends StatefulWidget {
  final String targetRoute;
  final String title;
  final String subtitle;
  final String badge;
  final Duration duration;
  final VoidCallback? onComplete;

  const TransitLoadingScreen({
    super.key,
    required this.targetRoute,
    this.title = 'CONECTANDO CON SMARTROUTE',
    this.subtitle = 'Iniciando sesión segura y sincronizando la unidad escolar TBX-492...',
    this.badge = 'AUTENTICACIÓN TRANSIT OS',
    this.duration = const Duration(milliseconds: 2200),
    this.onComplete,
  });

  /// Método estático de conveniencia para abrir la pantalla de carga hacia cualquier ruta
  static void open(
    BuildContext context, {
    required String targetRoute,
    String title = 'CONECTANDO CON SMARTROUTE',
    String subtitle = 'Iniciando sesión segura y sincronizando la unidad escolar TBX-492...',
    String badge = 'AUTENTICACIÓN TRANSIT OS',
    Duration duration = const Duration(milliseconds: 2100),
  }) {
    context.push(
      '/transit_loading',
      extra: {
        'targetRoute': targetRoute,
        'title': title,
        'subtitle': subtitle,
        'badge': badge,
        'duration': duration,
      },
    );
  }

  @override
  State<TransitLoadingScreen> createState() => _TransitLoadingScreenState();
}

class _TransitLoadingScreenState extends State<TransitLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );

    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        if (widget.onComplete != null) {
          widget.onComplete!();
        } else if (widget.targetRoute.isNotEmpty) {
          context.go(widget.targetRoute);
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  String _getDynamicStatusMessage(double progress) {
    if (progress < 0.28) {
      return 'Inicializando conexión cifrada con SmartRoute Cloud...';
    } else if (progress < 0.65) {
      return 'Localizando unidad Toyota HiAce • Rastreo satelital...';
    } else if (progress < 0.90) {
      return 'Descargando geometría de ruta, paradas y tráfico...';
    } else {
      return '¡Conexión establecida con éxito! Ingresando...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  final progress = _progressAnimation.value;
                  final percentage = (progress * 100).toInt();

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ----------------------------------------------------
                      // 1. Píldora superior oscura con indicador azul
                      // ----------------------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF040F16),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF01BAEF), // Punto azul vibrante
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.badge.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                color: const Color(0xFFEDEDEC),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ----------------------------------------------------
                      // 2. Subtítulo en tono slate sutil
                      // ----------------------------------------------------
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A5568),
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ----------------------------------------------------
                      // 3. Tarjeta Blanca Central con el autobús colegial
                      // ----------------------------------------------------
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0B4F6C).withValues(alpha: 0.08),
                              offset: const Offset(0, 14),
                              blurRadius: 36,
                              spreadRadius: -4,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              offset: const Offset(0, 2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Escena animada del autobús colegial
                            const BusTransitLoader(
                              width: double.infinity,
                              height: 145,
                            ),
                            const SizedBox(height: 14),

                            // Barra de progreso cian con track gris suave
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                height: 6.5,
                                width: double.infinity,
                                color: const Color(0xFFE2E8F0),
                                child: Stack(
                                  children: [
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress.clamp(0.02, 1.0),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF0B4F6C),
                                              Color(0xFF01BAEF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.all(Radius.circular(999)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Mensaje de estado dinámico y porcentaje
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _getDynamicStatusMessage(progress),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF334155),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$percentage%',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
