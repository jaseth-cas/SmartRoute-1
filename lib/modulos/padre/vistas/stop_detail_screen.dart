import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/status_chip.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class StopDetailScreen extends StatefulWidget {
  final String stopCode;

  const StopDetailScreen({
    super.key,
    required this.stopCode,
  });

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  late bool isFavorite;
  bool isAlertEnabled = true;

  @override
  void initState() {
    super.initState();
    final stop = MockData.stops.where((s) => s.stopCode == widget.stopCode).firstOrNull;
    isFavorite = stop?.isFavorite ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final stop = MockData.stops.where((s) => s.stopCode == widget.stopCode).firstOrNull;
    final route = stop != null ? MockData.getRouteByCode(stop.routeCode) : null;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'PARADA // ${widget.stopCode}',
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
          if (stop != null)
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
      body: stop == null
          ? const EmptyState(message: 'Parada no encontrada')
          : ResponsiveContent(
              maxWidth: 820,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                stop.stopCode,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: SmartColors.vibrantCyan,
                                ),
                              ),
                            ),
                            const Spacer(),
                            StatusChip(text: 'Orden #${stop.order}'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          stop.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stop.reference,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: SmartColors.smartGray,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        _DetailInfoRow(icon: Icons.map_rounded, label: 'RUTA ASOCIADA', value: route?.name ?? 'N/A'),
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.straighten_rounded,
                          label: 'DISTANCIA ACUMULADA',
                          value: '${stop.distanceFromStartKm} km',
                          isMono: true,
                        ),
                        if (stop.latitude != null) ...[
                          const SizedBox(height: 10),
                          _DetailInfoRow(
                            icon: Icons.pin_drop_rounded,
                            label: 'COORDENADAS GPS',
                            value: '${stop.latitude?.toStringAsFixed(4)}, ${stop.longitude?.toStringAsFixed(4)}',
                            isMono: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ETA Card Neumórfica
                  NeumorphicBox(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer_rounded, color: SmartColors.deepBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETA ESTIMADO A ESTA PARADA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: SmartColors.smartGray,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${route?.etaMinutes ?? 5}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MINUTOS',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: SmartColors.deepBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const StatusChip(text: 'Calculado'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'SELECCIONAR ESTA PARADA',
                    icon: Icons.check_circle_rounded,
                    onPressed: () => context.go('/map/${stop.routeCode}/${stop.stopCode}'),
                  ),
                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      setState(() => isAlertEnabled = !isAlertEnabled);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isAlertEnabled ? 'Alerta de proximidad activada.' : 'Alerta desactivada.'),
                          backgroundColor: SmartColors.deepBlue,
                        ),
                      );
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
                          Icon(
                            isAlertEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                            color: isAlertEnabled ? SmartColors.vibrantCyan : SmartColors.smartGray,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAlertEnabled ? 'ALERTA DE PROXIMIDAD ACTIVA' : 'ACTIVAR ALERTA DE PROXIMIDAD',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              letterSpacing: 0.8,
                              color: SmartColors.deepBlack,
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
