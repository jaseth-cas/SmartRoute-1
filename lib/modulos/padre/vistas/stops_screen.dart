import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/stop_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class StopsScreen extends StatelessWidget {
  final String routeCode;

  const StopsScreen({
    super.key,
    required this.routeCode,
  });

  @override
  Widget build(BuildContext context) {
    final stops = MockData.getStopsByRouteCode(routeCode);
    final route = MockData.getRouteByCode(routeCode);

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PARADAS // ${routeCode.toUpperCase()}',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 1.0,
                color: SmartColors.deepBlack,
              ),
            ),
            Text(
              route?.name ?? 'Ruta Escolar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: SmartColors.deepBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/routes',
        onNavigate: (route) => context.go(route),
      ),
      body: ResponsiveContent(
        maxWidth: 880,
        child: stops.isEmpty
            ? const Center(child: EmptyState(message: 'No hay paradas registradas para esta ruta.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                itemCount: stops.length + 1,
                separatorBuilder: (context, index) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return InfoBanner(
                      text: 'Sentido: ${route?.direction.name.toUpperCase() ?? "RESIDENCIAL → COLEGIO"}',
                      icon: Icons.alt_route_rounded,
                    );
                  }
                  final stop = stops[index - 1];
                  return StopCard(
                    stop: stop,
                    onSelect: () => context.go('/map/$routeCode/${stop.stopCode}'),
                    onDetail: () => context.go('/stop_detail/${stop.stopCode}'),
                  );
                },
              ),
      ),
    );
  }
}
