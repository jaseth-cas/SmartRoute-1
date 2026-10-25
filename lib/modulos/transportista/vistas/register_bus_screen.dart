import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/servicios/bus_service.dart';

class RegisterBusScreen extends StatefulWidget {
  const RegisterBusScreen({super.key});

  @override
  State<RegisterBusScreen> createState() => _RegisterBusScreenState();
}

class _RegisterBusScreenState extends State<RegisterBusScreen> {
  final _formKey = GlobalKey<FormState>();

  String code = "";
  String plate = "";
  String model = "";
  String capacity = "";
  String school = "Colegio San José";
  bool _isLoading = false;

  Future<void> _saveBus() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final busService = context.read<BusService>();
        final newBus = await busService.registerBus(
          code: code,
          plate: plate,
          model: model,
          capacity: int.parse(capacity),
          schoolName: school.isNotEmpty ? school : 'Colegio San José',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Autobús ${newBus.code} registrado correctamente en PostgreSQL'),
            backgroundColor: SmartColors.smartGreen,
          ),
        );

        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/owner_home');
        }
      } catch (e) {
        if (!mounted) return;
        final errorMsg = e.toString().contains('23505') || e.toString().contains('unique')
            ? 'Ya existe una unidad con ese código o placa en el sistema.'
            : 'Error al registrar unidad: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: SmartColors.smartRed,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Registrar Autobús', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/owner_home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                label: 'Código de Autobús',
                hint: 'Ej. BUS-03',
                prefixIcon: Icons.directions_bus,
                onChanged: (value) => code = value,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El código es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Placa del vehículo',
                hint: 'Ej. 123456',
                prefixIcon: Icons.pin,
                onChanged: (value) => plate = value,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'La placa es obligatoria';
                  if (val.length < 5) return 'Placa inválida';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Modelo',
                hint: 'Ej. Toyota Coaster',
                prefixIcon: Icons.car_repair,
                onChanged: (value) => model = value,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'El modelo es obligatorio';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Capacidad de pasajeros',
                hint: 'Ej. 30',
                prefixIcon: Icons.people,
                keyboardType: TextInputType.number,
                onChanged: (value) => capacity = value,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'La capacidad es obligatoria';
                  final numVal = int.tryParse(val);
                  if (numVal == null || numVal <= 0) return 'Ingresa un número válido mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: _isLoading ? 'Guardando en la base de datos...' : 'Guardar Autobús',
                icon: _isLoading ? null : Icons.save,
                enabled: !_isLoading,
                onPressed: _saveBus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
