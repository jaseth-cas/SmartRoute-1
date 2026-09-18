import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';

class AssignStopsScreen extends StatefulWidget {
  final String routeCode;

  const AssignStopsScreen({super.key, required this.routeCode});

  @override
  State<AssignStopsScreen> createState() => _AssignStopsScreenState();
}

class _AssignStopsScreenState extends State<AssignStopsScreen> {
  // En un caso real, cargaríamos el estado de asignación basado en this.routeCode
  final List<StopMock> stops = MockData.stops;
  final Map<String, bool> stopSelectionState = {};

  @override
  void initState() {
    super.initState();
    // Inicializar el estado de selección (simulado para R-BU, en otro caso todo false)
    for (var stop in stops) {
      stopSelectionState[stop.stopCode] = stop.routeCode == widget.routeCode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Asignar Paradas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/manage_routes');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: SmartColors.smartBlue),
            onPressed: () {
              // Simulated save
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/manage_routes');
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Selecciona las paradas que pertenecen a esta ruta.',
              style: TextStyle(fontSize: 12, color: SmartColors.smartGray),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: stops.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final stop = stops[index];
                final isSelected = stopSelectionState[stop.stopCode] ?? false;

                return SmartRouteCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: SmartColors.smartText)),
                            Text('Código: ${stop.stopCode} - Orden: ${stop.order}', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                          ],
                        ),
                      ),
                      Switch(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            stopSelectionState[stop.stopCode] = val;
                          });
                        },
                        activeThumbColor: SmartColors.smartBlue,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
