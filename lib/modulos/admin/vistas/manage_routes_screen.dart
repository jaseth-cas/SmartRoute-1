import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/smart_route_card.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  late List<RouteMock> routesList;
  int routeCounter = 3;

  @override
  void initState() {
    super.initState();
    routesList = List.from(MockData.routes);
  }

  void _showAddRouteDialog() {
    final formKey = GlobalKey<FormState>();
    String newName = "";
    String newOrigin = "";
    String newDestination = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Agregar Nueva Ruta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nombre de la Ruta',
                  hint: 'Ej. Ruta Periférica',
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onChanged: (val) => newName = val,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Origen',
                  hint: 'Ej. Terminal Norte',
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onChanged: (val) => newOrigin = val,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Destino',
                  hint: 'Ej. Universidad',
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                  onChanged: (val) => newDestination = val,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Crear Ruta',
                  icon: Icons.add_road,
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final newRoute = RouteMock(
                        id: routeCounter,
                        code: 'R-NUEVA-$routeCounter',
                        name: newName,
                        origin: newOrigin,
                        destination: newDestination,
                        status: 'Activa',
                        etaMinutes: 0,
                        busCode: 'N/A',
                        direction: RouteDirection.boulevardToUniversity,
                        description: 'Ruta añadida dinámicamente',
                        isFavorite: false,
                      );
                      setState(() {
                        routesList.insert(0, newRoute);
                        routeCounter++;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Gestión de rutas', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Administra las rutas simuladas del sistema.',
              style: TextStyle(fontSize: 12, color: SmartColors.smartGray),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _showAddRouteDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.smartBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar ruta simulada', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: routesList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final route = routesList[index];
                return _ManageRouteItem(
                  route: route,
                  onDelete: () {
                    setState(() {
                      routesList.removeAt(index);
                    });
                  },
                  onToggleStatus: () {
                    setState(() {
                      final newStatus = route.status == "Activa" ? "Inactiva" : "Activa";
                      routesList[index] = route.copyWith(status: newStatus);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageRouteItem extends StatelessWidget {
  final RouteMock route;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _ManageRouteItem({
    required this.route,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRouteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SmartColors.smartLightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on, color: SmartColors.smartBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SmartColors.smartText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(text: route.status),
                      ],
                    ),
                    Text('Código: ${route.code}', style: const TextStyle(fontSize: 12, color: SmartColors.smartGray)),
                    Text('Sentido: ${route.direction.name.toUpperCase()}', style: const TextStyle(fontSize: 12, color: SmartColors.smartBlue)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: SmartColors.smartGray),
                onPressed: () {
                  // Simulated Edit
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Eliminar', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SmartColors.smartRed,
                    side: const BorderSide(color: SmartColors.smartLightRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(route.status == "Activa" ? Icons.block : Icons.check_circle, size: 16),
                  label: Text(route.status == "Activa" ? "Inactivar" : "Activar", style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: route.status == "Activa" ? SmartColors.smartGray : SmartColors.smartGreen,
                    side: BorderSide(color: route.status == "Activa" ? SmartColors.smartBorder : SmartColors.smartLightGreen),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push('/assign_stops/${route.code}'),
            icon: const Icon(Icons.format_list_numbered, size: 18),
            label: const Text('Gestionar Paradas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: SmartColors.smartLightBlue,
              foregroundColor: SmartColors.smartBlue,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;

  const _StatusBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final isActive = text == "Activa";
    final color = isActive ? SmartColors.smartGreen : SmartColors.smartGray;
    final bgColor = isActive ? SmartColors.smartLightGreen : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
