import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/utilidades/validators.dart';
import '../../autenticacion/datos/session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    // Simulate loading data from session
    final session = context.read<SessionManager>().currentSession;
    _name = session?.name ?? 'Usuario';
    _email = session?.email ?? 'correo@universidad.edu';
    _phone = '555-0192'; // Mock phone
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Simulate saving profile logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: SmartColors.smartGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: SmartColors.smartLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 60, color: SmartColors.smartBlue),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: SmartColors.smartBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              CustomTextField(
                label: 'Nombre completo',
                hint: 'Ingresa tu nombre',
                prefixIcon: Icons.badge,
                controller: TextEditingController(text: _name),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
                onChanged: (val) => _name = val,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: 'Correo electrónico',
                hint: 'estudiante@universidad.edu',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                controller: TextEditingController(text: _email),
                validator: Validators.validateEmail,
                onChanged: (val) => _email = val,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: 'Teléfono',
                hint: 'Tu número de teléfono',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                controller: TextEditingController(text: _phone),
                onChanged: (val) => _phone = val,
              ),
              const SizedBox(height: 32),
              
              PrimaryButton(
                text: 'Guardar cambios',
                icon: Icons.save,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
