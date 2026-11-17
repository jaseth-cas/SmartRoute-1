import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class EtaScreen extends StatefulWidget {
  final String routeCode;
  final String stopCode;

  const EtaScreen({
    super.key,
    required this.routeCode,
    required this.stopCode,
  });

  @override
  State<EtaScreen> createState() => _EtaScreenState();
}

class _EtaScreenState extends State<EtaScreen> {
  int? _calculatedEta;
  RouteMock? _route;
  StopMock? _stop;
  BusMock? _bus;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    try {
      final busService = context.read<BusService>();
      final results = await Future.wait([
        busService.getRouteByCode(widget.routeCode),
        busService.getStopByCode(widget.stopCode),
        busService.getBusByCode(widget.routeCode),
      ]);
      if (mounted) {
        setState(() {
          _route = results[0] as RouteMock?;
          _stop = results[1] as StopMock?;
          _bus = results[2] as BusMock?;
        });
      }
    } catch (e) {
      debugPrint('Error cargando telemetría ETA: $e');
    }
  }

  void _recalculateEta() {
    final stop = _stop;
    final bus = _bus;

    final distanceKm = (stop != null && stop.distanceFromStartKm > 0)
        ? stop.distanceFromStartKm
        : 2.5;
    final speedKmH = (bus != null && bus.currentSpeedKmH > 0) ? bus.currentSpeedKmH : 32;

    setState(() {
      _calculatedEta = AppConstants.calculateEtaMinutes(
        distanceKm: distanceKm,
        speedKmH: speedKmH,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ETA actualizado en vivo: $_calculatedEta minutos ($distanceKm km a $speedKmH km/h)'),
        backgroundColor: SmartColors.deepBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final stop = _stop;
    final bus = _bus;
    final distanceKm = (stop != null && stop.distanceFromStartKm > 0)
        ? stop.distanceFromStartKm
        : 2.5;
    final etaValue = _calculatedEta ?? route?.etaMinutes ?? 5;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Text(
            'TELEMETRÍA // ETA EN TIEMPO REAL',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: SmartColors.deepBlack,
            ),
          ),
          backgroundColor: SmartColors.neuBackground,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: NeumorphicBox(
              padding: EdgeInsets.zero,
              isPill: true,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 18, color: SmartColors.deepBlack),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/routes');
                  }
                },
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  tooltip: 'Recalcular ETA',
                  icon: const Icon(Icons.refresh_rounded, color: SmartColors.deepBlue, size: 18),
                  onPressed: _recalculateEta,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: StudentBottomBar(
          currentRoute: '/eta',
          onNavigate: (route) => context.go(route),
        ),
        body: ResponsiveContent(
          maxWidth: 760,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Medidor Central Neumórfico Quivox
                NeumorphicBox(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  borderRadius: BorderRadius.circular(30),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlack,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ESTIMATED TIME OF ARRIVAL',
                          style: GoogleFonts.jetBrainsMono(
                            color: SmartColors.vibrantCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$etaValue',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2.5,
                              color: SmartColors.deepBlack,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'MIN',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: SmartColors.deepBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Regla métrica estilo Quivox
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(21, (index) {
                          final isCenter = index == 10;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: 2,
                            height: isCenter ? 26 : (index % 5 == 0 ? 16 : 8),
                            color: isCenter
                                ? SmartColors.vibrantCyan
                                : SmartColors.smartGray.withValues(alpha: 0.3),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      const StatusChip(text: 'Tráfico fluido • GPS activo'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Detalles en tabla inset esculpida
                NeumorphicBox(
                  isInset: true,
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      _DetailInfoRow(
                        icon: Icons.alt_route_rounded,
                        label: 'RUTA ESCOLAR',
                        value: route?.name ?? 'Ruta Escolar Norte',
                      ),
                      const Divider(height: 20),
                      _DetailInfoRow(
                        icon: Icons.pin_drop_rounded,
                        label: 'PUNTO DE PARADA',
                        value: stop?.name ?? 'Parada escolar',
                      ),
                      const Divider(height: 20),
                      _DetailInfoRow(
                        icon: Icons.social_distance_rounded,
                        label: 'DISTANCIA TELEMÉTRICA',
                        value: '$distanceKm km',
                        isMono: true,
                      ),
                      const Divider(height: 20),
                      _DetailInfoRow(
                        icon: Icons.directions_bus_rounded,
                        label: 'UNIDAD ASIGNADA',
                        value: bus != null ? '${bus.code} (${bus.plate})' : 'Sin unidad asignada',
                        isMono: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const InfoBanner(
                  text: 'El bus escolar se encuentra en camino. ETA calculado con telemetría en vivo.',
                  icon: Icons.radar_rounded,
                ),
                const SizedBox(height: 24),

                PrimaryButton(
                  text: 'VER EN MAPA INTERACTIVO',
                  icon: Icons.explore_rounded,
                  onPressed: () => context.push('/map/${widget.routeCode}/${widget.stopCode}'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMono;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SmartColors.deepBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: SmartColors.deepBlue, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                  color: SmartColors.smartGray,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: isMono
                    ? GoogleFonts.jetBrainsMono(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: SmartColors.deepBlack,
                      )
                    : GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: SmartColors.deepBlack,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
