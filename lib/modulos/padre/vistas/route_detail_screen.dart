import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/section_title.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeCode;

  const RouteDetailScreen({
    super.key,
    required this.routeCode,
  });

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
    final route = MockData.getRouteByCode(widget.routeCode);
    isFavorite = route?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(widget.routeCode);

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'RUTA // ${widget.routeCode}',
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
          if (route != null)
            Padding(
              padding: const EdgeInsets.only(right: 14.0),
              child: NeumorphicBox(
                padding: EdgeInsets.zero,
                isPill: true,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? SmartColors.primaryCrimson : SmartColors.smartGray,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
      body: route == null
          ? const EmptyState(message: 'Ruta no encontrada')
          : ResponsiveContent(
              maxWidth: 820,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Tarjeta Principal de Ruta
                  NeumorphicBox(
                    padding: const EdgeInsets.all(22),
                    borderRadius: BorderRadius.circular(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartColors.deepBlack,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                route.code,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: SmartColors.vibrantCyan,
                                ),
                              ),
                            ),
                            const Spacer(),
                            StatusChip(text: route.status),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          route.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${route.origin} → ${route.destination}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: SmartColors.smartGray,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _DetailInfoRow(icon: Icons.trip_origin_rounded, label: 'ORIGEN', value: route.origin),
                        const SizedBox(height: 10),
                        _DetailInfoRow(icon: Icons.location_on_rounded, label: 'DESTINO', value: route.destination),
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.directions_bus_rounded,
                          label: 'BUS ASIGNADO',
                          value: route.busCode ?? "No asignado",
                          isMono: true,
                        ),
                        const SizedBox(height: 10),
                        _DetailInfoRow(icon: Icons.person_rounded, label: 'CONDUCTOR', value: route.busCode == "BUS-01" ? "Carlos Pérez" : "Luis Gómez"),
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.timer_rounded,
                          label: 'ETA CALCULADO',
                          value: route.etaMinutes != null ? "${route.etaMinutes} min" : "N/A",
                          isMono: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Descripción en caja Inset
                  SectionTitle(text: 'Itinerario y Propósito', subtext: 'RESUMEN OPERATIVO'),
                  NeumorphicBox(
                    isInset: true,
                    padding: const EdgeInsets.all(18),
                    borderRadius: BorderRadius.circular(20),
                    child: Text(
                      route.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: SmartColors.deepBlack,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Métricas Técnicas Quivox ("12/34", "10")
                  SectionTitle(text: 'Telemetría de Ruta', subtext: 'MÉTRICAS'),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricMiniCard(
                          icon: Icons.format_list_numbered_rounded,
                          value: MockData.getStopsByRouteCode(route.code).length.toString().padLeft(2, '0'),
                          label: 'PARADAS PROGRAMADAS',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricMiniCard(
                          icon: Icons.straighten_rounded,
                          value: route.code == "R-BU" ? "4.5 km" : "9.0 km",
                          label: 'DISTANCIA TOTAL',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'VER PARADAS DE LA RUTA',
                    icon: Icons.format_list_numbered_rounded,
                    onPressed: () => context.go('/stops/${route.code}'),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      final stopCode = MockData.getStopsByRouteCode(route.code).firstOrNull?.stopCode ?? "P-BU-001";
                      context.go('/map/${route.code}/$stopCode');
                    },
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: SmartColors.neuInset,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.explore_rounded, color: SmartColors.deepBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'RASTREAR EN VIVO',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.8,
                              color: SmartColors.deepBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
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
      children: [
        Icon(icon, color: SmartColors.deepBlue, size: 16),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: SmartColors.smartGray,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: isMono
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.deepBlack,
                )
              : GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SmartColors.deepBlack,
                ),
        ),
      ],
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricMiniCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SmartColors.vibrantCyan, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.5,
              color: SmartColors.deepBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: SmartColors.smartGray,
            ),
          ),
        ],
      ),
    );
  }
}
