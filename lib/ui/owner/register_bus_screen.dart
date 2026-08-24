import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/colors.dart';
import '../components/primary_button.dart';

class RegisterBusScreen extends StatefulWidget {
  const RegisterBusScreen({super.key});

  @override
  State<RegisterBusScreen> createState() => _RegisterBusScreenState();
}

class _RegisterBusScreenState extends State<RegisterBusScreen> {
  String code = "";
  String plate = "";
  String model = "";
  String capacity = "";

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => code = value,
              decoration: const InputDecoration(
                labelText: 'Código de Autobús (Ej. BUS-03)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => plate = value,
              decoration: const InputDecoration(
                labelText: 'Placa del vehículo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => model = value,
              decoration: const InputDecoration(
                labelText: 'Modelo (Ej. Toyota Coaster)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => capacity = value,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Capacidad de pasajeros',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: 'Guardar Autobús',
              icon: Icons.save,
              onPressed: () {
                // Simulate save and return
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/owner_home');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
