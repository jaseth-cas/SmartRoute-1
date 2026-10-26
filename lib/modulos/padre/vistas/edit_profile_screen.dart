import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/neumorphic_box.dart';
import '../../../nucleo/widgets/responsive_layout.dart';
import '../../../nucleo/utilidades/validators.dart';
import '../../autenticacion/datos/session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionManager>().currentSession;
    _nameController = TextEditingController(text: session?.name ?? 'Carlos Gómez');
    _emailController = TextEditingController(text: session?.email ?? 'carlos.gomez@smartroute.com');
    _phoneController = TextEditingController(text: '+57 300 123 4567');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil de tutor actualizado con éxito.'),
          backgroundColor: SmartColors.deepBlue,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        title: Text(
          'CONFIG // EDITAR PERFIL',
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
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: ResponsiveContent.narrow(
        maxWidth: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              const SizedBox(height: 10),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  NeumorphicBox(
                    width: 100,
                    height: 100,
                    borderRadius: BorderRadius.circular(34),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 50, color: SmartColors.deepBlue),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SmartColors.deepBlack,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.deepBlack.withValues(alpha: 0.25),
                          offset: const Offset(0, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: SmartColors.vibrantCyan, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              
              CustomTextField(
                label: 'Nombre de Tutor',
                hint: 'Ingresa tu nombre',
                prefixIcon: Icons.badge_outlined,
                controller: _nameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: 'Correo de Notificaciones',
                hint: 'correo@ejemplo.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                label: 'Teléfono Móvil (SMS Alertas)',
                hint: 'Ingresa tu teléfono',
                prefixIcon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El teléfono es requerido para emergencias';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'GUARDAR CAMBIOS',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
