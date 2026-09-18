import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  String searchQuery = "";
  String selectedFilter = "Todas";

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = MockData.routes.where((route) {
      final matchesSearch = route.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          route.destination.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesFilter = switch (selectedFilter) {
        "Activas" => route.status == "Activa",
        "Favoritas" => route.isFavorite,
        _ => true,
      };
      return matchesSearch && matchesFilter;
    }).toList();

    return PopScope(
      canPop: context.canPop(),
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Rutas disponibles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student_home');
            }
          },
        ),
      ),
      bottomNavigationBar: StudentBottomBar(
        currentRoute: '/routes',
        onNavigate: (route) => context.go(route),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar ruta o destino',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SmartColors.smartBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: SmartColors.smartBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip("Todas"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Activas"),
                    const SizedBox(width: 8),
                    _buildFilterChip("Favoritas"),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredRoutes.isEmpty
                ? const EmptyState(message: 'No se encontraron rutas que coincidan con tu búsqueda.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredRoutes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final route = filteredRoutes[index];
                      return RouteCard(
                        route: route,
                        onDetailClick: () => context.push('/route_detail/${route.code}'),
                        onStopsClick: () => context.push('/stops/${route.code}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    ));
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() => selectedFilter = label);
        }
      },
      selectedColor: SmartColors.smartBlue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : SmartColors.smartText,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
