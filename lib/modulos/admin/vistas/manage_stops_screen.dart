import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/modulos/admin/utilidades/admin_validators.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/smart_route_card.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/admin_bottom_bar.dart';

class ManageStopsScreen extends StatefulWidget {
  const ManageStopsScreen({super.key});

  @override
  State<ManageStopsScreen> createState() => _ManageStopsScreenState();
}

class _ManageStopsScreenState extends State<ManageStopsScreen> {
  late List<StopMock> stopsList;
  int stopCounter = 100;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalStops();
  }

  Future<void> _loadLocalStops() async {
    await MockData.loadStops();
    setState(() {
      stopsList = List.from(MockData.stops);
      if (MockData.stops.isNotEmpty) {
        final maxId = MockData.stops.map((s) => s.id).reduce((a, b) => a > b ? a : b);
        stopCounter = maxId + 1;
      } else {
        stopCounter = 1;
      }
      _isLoading = false;
    });
  }

  void _showAddStopDialog() {
    final formKey = GlobalKey<FormState>();
    String newName = "";
    String newLat = "";
    String newLng = "";
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
                      const Text('Agregar Nueva Parada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SmartColors.smartRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: SmartColors.smartRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Nombre de la parada',
                        hint: 'Ej. Parada Biblioteca',
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        onChanged: (val) => newName = val,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Latitud',
                              hint: 'Ej. 8.9823',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                              onChanged: (val) => newLat = val,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Longitud',
                              hint: 'Ej. -79.5209',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                              onChanged: (val) => newLng = val,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Guardar Parada',
                        icon: Icons.add_location,
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final String? errorMsg = AdminRouteValidator.validateNewStopData(
                              name: newName,
                              lat: newLat,
                              lng: newLng,
                            );

                            if (errorMsg != null) {
                              setModalState(() {
                                errorMessage = errorMsg;
                              });
                              return;
                            }

                            final newStop = StopMock(
                              id: stopCounter,
                              stopCode: 'S-NUEVA-$stopCounter',
                              routeCode: 'R-N/A', // Sin asignar inicialmente
                              name: newName,
                              latitude: double.tryParse(newLat) ?? 0.0,
                              longitude: double.tryParse(newLng) ?? 0.0,
                              reference: 'Agregada por administrador',
                              order: 0,
                              distanceFromStartKm: 0.0,
                              isFavorite: false,
                            );
                            setState(() {
                              stopsList.insert(0, newStop);
                              MockData.stops.insert(0, newStop); // Guardar globalmente
                              stopCounter++;
                            });
                            MockData.saveStops(); // Guardar en SharedPreferences
                            Navigator.pop(context);
                          }
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

  void _showEditStopDialog(StopMock stop, int index) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: stop.name);
    final latCtrl = TextEditingController(text: stop.latitude?.toString() ?? '');
    final lngCtrl = TextEditingController(text: stop.longitude?.toString() ?? '');
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
                      const Text('Editar Parada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: SmartColors.smartRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(errorMessage!, style: const TextStyle(color: SmartColors.smartRed, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Nombre de la parada',
                        controller: nameCtrl,
                        validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Latitud',
                              controller: latCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Longitud',
                              controller: lngCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Guardar Cambios',
                        icon: Icons.save,
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            final String? errorMsg = AdminRouteValidator.validateNewStopData(
                              name: nameCtrl.text,
                              lat: latCtrl.text,
                              lng: lngCtrl.text,
                            );

                            if (errorMsg != null) {
                              setModalState(() {
                                errorMessage = errorMsg;
                              });
                              return;
                            }

                            final updatedStop = stop.copyWith(
                              name: nameCtrl.text,
                              latitude: double.tryParse(latCtrl.text) ?? 0.0,
                              longitude: double.tryParse(lngCtrl.text) ?? 0.0,
                            );

                            setState(() {
                              stopsList[index] = updatedStop;
                              final mockIndex = MockData.stops.indexWhere((s) => s.id == stop.id);
                              if (mockIndex != -1) {
                                MockData.stops[mockIndex] = updatedStop;
                              }
                            });
                            MockData.saveStops(); // Guardar en SharedPreferences
                            Navigator.pop(context);
                          }
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: SmartColors.smartBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Gestión de paradas', style: TextStyle(fontWeight: FontWeight.bold, color: SmartColors.smartBlue)),
          backgroundColor: Colors.white,
          elevation: 1,
        ),
        bottomNavigationBar: AdminBottomBar(
          currentRoute: '/manage_stops',
          onNavigate: (route) => context.go(route),
        ),
        floatingActionButton: FloatingActionButton(
        onPressed: _showAddStopDialog,
        backgroundColor: SmartColors.smartBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: stopsList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ManageStopItem(
            stop: stopsList[index],
            onEdit: () => _showEditStopDialog(stopsList[index], index),
            onDelete: () {
              setState(() {
                MockData.stops.removeWhere((s) => s.id == stopsList[index].id); // Global
                stopsList.removeAt(index); // Local UI
              });
              MockData.saveStops(); // Guardar en SharedPreferences
            },
          );
        },
      ),
      ),
    );
  }
}

class _ManageStopItem extends StatelessWidget {
  final StopMock stop;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ManageStopItem({
    required this.stop, 
    required this.onDelete,
    required this.onEdit,
  });

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
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: SmartColors.smartRed),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
