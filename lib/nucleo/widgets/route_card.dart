import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'status_chip.dart';

class RouteCard extends StatelessWidget {
  final RouteMock route;
  final VoidCallback onDetailClick;
  final VoidCallback onStopsClick;

  const RouteCard({
    super.key,
    required this.route,
    required this.onDetailClick,
    required this.onStopsClick,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicBox(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono en cápsula neumórfica
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: SmartColors.deepBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.alt_route_rounded, color: SmartColors.deepBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Código técnico tipo Quivox ("COMPOUND 1")
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlack,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            route.code,
                            style: GoogleFonts.jetBrainsMono(
                              color: SmartColors.vibrantCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            route.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: SmartColors.deepBlack,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (route.isFavorite) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.favorite_rounded, color: SmartColors.primaryCrimson, size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.origin} → ${route.destination}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: SmartColors.smartGray,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              StatusChip(text: route.status),
              const SizedBox(width: 8),
              if (route.status == 'Activa' && route.etaMinutes != null)
                StatusChip(text: 'ETA ${route.etaMinutes} MIN')
              else if (route.status == 'Inactiva')
                const StatusChip(text: 'FUERA DE SERVICIO'),
              const Spacer(),
              if (route.busCode != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SmartColors.neuInset,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus_rounded, size: 13, color: SmartColors.deepBlue),
                      const SizedBox(width: 5),
                      Text(
                        route.busCode!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.deepBlue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Botones de acción en cápsula Quivox
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDetailClick,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: SmartColors.neuInset,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'DETALLES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onStopsClick,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: SmartColors.deepBlack,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.deepBlack.withValues(alpha: 0.25),
                          offset: const Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'VER PARADAS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: SmartColors.ghostWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
