import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/student_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/route_card.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  String searchQuery = "";
  String selectedFilter = "Todas";

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? SmartColors.deepBlack : SmartColors.ghostWhite,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SmartColors.deepBlack.withValues(alpha: 0.25),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.white,
                    offset: const Offset(-2, -2),
                    blurRadius: 6,
                  ),
                  BoxShadow(
                    color: SmartColors.deepBlue.withValues(alpha: 0.06),
                    offset: const Offset(2, 3),
                    blurRadius: 6,
                  ),
                ],
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isSelected ? SmartColors.ghostWhite : SmartColors.deepBlue,
          ),
        ),
      ),
    );
  }

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
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/student_home');
        }
      },
      child: Scaffold(
        backgroundColor: SmartColors.neuBackground,
        appBar: AppBar(
          title: Text(
            'CATÁLOGO // RUTAS ESCOLARES',
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
                    context.go('/student_home');
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
          maxWidth: 980,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Buscador Neumórfico Inset
                    Container(
                      decoration: BoxDecoration(
                        color: SmartColors.neuInset,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: SmartColors.deepBlue.withValues(alpha: 0.05),
                            offset: const Offset(1.5, 2),
                            blurRadius: 4,
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            offset: Offset(-1.5, -2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SmartColors.deepBlack,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar por colegio, ruta o destino...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: SmartColors.smartGray,
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, color: SmartColors.deepBlue, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                    ? const EmptyState(
                        message: 'No se encontraron rutas',
                        subMessage: 'Intenta con otro término o filtro de búsqueda.',
                        icon: Icons.alt_route_rounded,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final bool isWide = constraints.maxWidth >= 720;
                          if (isWide) {
                            return GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.85,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: filteredRoutes.length,
                              itemBuilder: (context, index) {
                                final route = filteredRoutes[index];
                                return RouteCard(
                                  route: route,
                                  onDetailClick: () => context.push('/route_detail/${route.code}'),
                                  onStopsClick: () => context.push('/stops/${route.code}'),
                                );
                              },
                            );
                          } else {
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredRoutes.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final route = filteredRoutes[index];
                                return RouteCard(
                                  route: route,
                                  onDetailClick: () => context.push('/route_detail/${route.code}'),
                                  onStopsClick: () => context.push('/stops/${route.code}'),
                                );
                              },
                            );
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
