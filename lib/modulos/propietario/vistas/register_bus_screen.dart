import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/custom_text_field.dart';

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

  void _saveBus() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Simulate save and return
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autobús registrado correctamente'),
          backgroundColor: SmartColors.smartGreen,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/owner_home');
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
                text: 'Guardar Autobús',
                icon: Icons.save,
                onPressed: _saveBus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
