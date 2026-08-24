import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../../data/models/models.dart';
import '../theme/colors.dart';
import '../components/smart_route_card.dart';

class ManageStopsScreen extends StatelessWidget {
  const ManageStopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Gestión de paradas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin_home');
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Visual
        },
        backgroundColor: SmartColors.smartBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: MockData.stops.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ManageStopItem(stop: MockData.stops[index]);
        },
      ),
    );
  }
}

class _ManageStopItem extends StatelessWidget {
  final StopMock stop;

  const _ManageStopItem({required this.stop});

  @override
  Widget build(BuildContext context) {
    final route = MockData.getRouteByCode(stop.routeCode);
    
    return SmartRouteCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SmartColors.smartText)),
                Text('Código: ${stop.stopCode}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SmartColors.smartGray)),
                Text('Ruta: ${route?.name ?? stop.routeCode}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: SmartColors.smartBlue)),
                Text('Referencia: ${stop.reference}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SmartColors.smartGray)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: SmartColors.smartBlue),
                onPressed: () {
                  // Visual
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: SmartColors.smartRed),
                onPressed: () {
                  // Visual
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
