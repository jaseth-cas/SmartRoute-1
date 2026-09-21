import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/smart_route_card.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../utilidades/admin_validators.dart';

class ManageRoutesScreen extends StatefulWidget {
  const ManageRoutesScreen({super.key});

  @override
  State<ManageRoutesScreen> createState() => _ManageRoutesScreenState();
}

class _ManageRoutesScreenState extends State<ManageRoutesScreen> {
  late List<RouteMock> routesList = [];
  int routeCounter = 3;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalRoutes();
  }

  Future<void> _loadLocalRoutes() async {
    await MockData.loadRoutes();
    setState(() {
      routesList = List.from(MockData.routes);
      if (MockData.routes.isNotEmpty) {
        final maxId = MockData.routes.map((r) => r.id).reduce((a, b) => a > b ? a : b);
        routeCounter = maxId + 1;
      } else {
        routeCounter = 1;
      }
      _isLoading = false;
    });
  }

  void _showAddRouteDialog() {
    final formKey = GlobalKey<FormState>();
    String newName = "";
    String newOrigin = "";
    String newDestination = "";

    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Agregar Nueva Ruta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SmartColors.smartLightRed, borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: SmartColors.smartRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
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
                          // Usa el nuevo validador (Caja Blanca) para verificar los campos
                          final validationError = AdminRouteValidator.validateNewRouteData(
                            name: newName,
                            origin: newOrigin,
                            destination: newDestination,
                          );

                          if (validationError != null) {
                            setModalState(() {
                              errorMessage = validationError;
                            });
                            return;
                          }

                          // Happy path (Todos los datos son válidos)
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
                            MockData.routes.insert(0, newRoute); // Guardar globalmente en la memoria de la app
                            routeCounter++;
                          });
                          MockData.saveRoutes(); // Guardar en SharedPreferences
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditRouteDialog(RouteMock route, int index) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: route.name);
    final originCtrl = TextEditingController(text: route.origin);
    final destCtrl = TextEditingController(text: route.destination);

    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Editar Ruta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SmartColors.smartLightRed, borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: SmartColors.smartRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Nombre de la Ruta',
                        controller: nameCtrl,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Origen',
                        controller: originCtrl,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'Destino',
                        controller: destCtrl,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Guardar Cambios',
                        icon: Icons.save,
                        onPressed: () {
                          final validationError = AdminRouteValidator.validateNewRouteData(
                            name: nameCtrl.text,
                            origin: originCtrl.text,
                            destination: destCtrl.text,
                          );

                          if (validationError != null) {
                            setModalState(() {
                              errorMessage = validationError;
                            });
                            return;
                          }

                          final updatedRoute = route.copyWith(
                            name: nameCtrl.text,
                            origin: originCtrl.text,
                            destination: destCtrl.text,
                          );

                          setState(() {
                            routesList[index] = updatedRoute;
                            final mockIndex = MockData.routes.indexWhere((r) => r.id == route.id);
                            if (mockIndex != -1) {
                              MockData.routes[mockIndex] = updatedRoute;
                            }
                          });
                          MockData.saveRoutes(); // Guardar cambios en SharedPreferences
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
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
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
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
                  onEdit: () => _showEditRouteDialog(route, index),
                  onDelete: () {
                    setState(() {
                      MockData.routes.removeWhere((r) => r.id == route.id); // Global
                      routesList.removeAt(index); // Local UI
                    });
                    MockData.saveRoutes(); // Guardar en SharedPreferences
                  },
                  onToggleStatus: () {
                    setState(() {
                      final newStatus = route.status == "Activa" ? "Inactiva" : "Activa";
                      final updated = route.copyWith(status: newStatus);
                      routesList[index] = updated;
                      final mockIndex = MockData.routes.indexWhere((r) => r.id == route.id);
                      if (mockIndex != -1) {
                        MockData.routes[mockIndex] = updated;
                      }
                    });
                    MockData.saveRoutes(); // Guardar en SharedPreferences
                  },
                );
              },
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _ManageRouteItem extends StatelessWidget {
  final RouteMock route;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  final VoidCallback onEdit;

  const _ManageRouteItem({
    required this.route,
    required this.onDelete,
    required this.onToggleStatus,
    required this.onEdit,
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
                onPressed: onEdit,
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
