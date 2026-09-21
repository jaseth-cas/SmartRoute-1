import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/smart_route_card.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';

class ManageStopsScreen extends StatefulWidget {
  const ManageStopsScreen({super.key});

  @override
  State<ManageStopsScreen> createState() => _ManageStopsScreenState();
}

class _ManageStopsScreenState extends State<ManageStopsScreen> {
  late List<StopMock> stopsList;
  int stopCounter = 100;

  @override
  void initState() {
    super.initState();
    stopsList = List.from(MockData.stops);
  }

  void _showAddStopDialog() {
    final formKey = GlobalKey<FormState>();
    String newName = "";
    String newLat = "";
    String newLng = "";

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Agregar Nueva Parada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                          onChanged: (val) => newLat = val,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Longitud',
                          hint: 'Ej. -79.5209',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          stopCounter++;
                        });
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
  }

  void _showEditStopDialog(StopMock stop, int index) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: stop.name);
    final latCtrl = TextEditingController(text: stop.latitude?.toString() ?? '');
    final lngCtrl = TextEditingController(text: stop.longitude?.toString() ?? '');

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Editar Parada', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          label: 'Longitud',
                          controller: lngCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
  }

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
        onPressed: _showAddStopDialog,
        backgroundColor: SmartColors.smartBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
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
            },
          );
        },
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
