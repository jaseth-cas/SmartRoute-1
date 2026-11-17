import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/stop_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/info_banner.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

class StopsScreen extends StatefulWidget {
  final String routeCode;

  const StopsScreen({
    super.key,
    required this.routeCode,
  });

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  List<StopMock> _stops = [];
  RouteMock? _route;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final busService = context.read<BusService>();
      final results = await Future.wait([
        busService.getStopsByBusCode(widget.routeCode),
        busService.getRouteByCode(widget.routeCode),
      ]);
      if (mounted) {
        setState(() {
          _stops = results[0] as List<StopMock>;
          _route = results[1] as RouteMock?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando paradas: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    final route = _route;
    final routeCode = widget.routeCode;

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: SmartColors.deepBlue))
            : stops.isEmpty
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
                        onSelect: () {
                          TransitLoadingScreen.open(
                            context,
                            targetRoute: '/map/$routeCode/${stop.stopCode}',
                            title: 'CARGANDO PARADA EN MAPA',
                            subtitle: 'Localizando parada ${stop.name}...',
                            badge: 'RASTREO EN VIVO',
                          );
                        },
                        onDetail: () => context.go('/stop_detail/${stop.stopCode}'),
                      );
                    },
                  ),
      ),
    );
  }
}
