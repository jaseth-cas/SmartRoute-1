import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/stop_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';

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
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paradas de la ruta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(route?.name ?? 'Ruta', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/routes');
            }
          },
        ),
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/routes', // Treating stops as a sub-route of routes for bottom bar highlighting
        onNavigate: (route) => context.go(route),
      ),
      body: stops.isEmpty
          ? const Center(child: EmptyState(message: 'No hay paradas registradas para esta ruta.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: stops.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return InfoBanner(text: 'Sentido: ${route?.direction.name.toUpperCase() ?? "N/A"}');
                }
                final stop = stops[index - 1];
                return StopCard(
                  stop: stop,
                  onSelect: () => context.go('/map/$routeCode/${stop.stopCode}'),
                  onDetail: () => context.go('/stop_detail/${stop.stopCode}'),
                );
              },
            ),
    );
  }
}
