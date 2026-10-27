import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/custom_text_field.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/continuous_tabs.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _name = '';
  String _email = '';
  String _password = '';
  UserRole _selectedRole = UserRole.student;

  void _register() {
    if (_formKey.currentState!.validate() && _password.isNotEmpty) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuenta creada para ${_name.isNotEmpty ? _name : _email}. Inicia sesión.'),
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
          'REGISTRO // NUEVO USUARIO',
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crea tu Perfil',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: SmartColors.deepBlack,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Únete a la red segura de transporte escolar SmartRoute',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: SmartColors.smartGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Selector de Rol tipo Quivox Segmented Pill
                    ContinuousTabs<UserRole>(
                      selected: _selectedRole,
                      onChanged: (role) => setState(() => _selectedRole = role),
                      tabs: const [
                        ContinuousTabItem(value: UserRole.student, label: 'PADRE'),
                        ContinuousTabItem(value: UserRole.driver, label: 'CHOFER'),
                        ContinuousTabItem(value: UserRole.owner, label: 'DUEÑO'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    CustomTextField(
                      label: 'Nombre Completo',
                      hint: 'Ej. Roberto Morales',
                      prefixIcon: Icons.badge_outlined,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'El nombre es requerido';
                        return null;
                      },
                      onChanged: (val) => _name = val,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Correo Electrónico',
                      hint: 'correo@ejemplo.com',
                      prefixIcon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      onChanged: (val) => _email = val,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Contraseña de Seguridad',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: Validators.validatePassword,
                      onChanged: (val) => _password = val,
                    ),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: 'COMPLETAR REGISTRO',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _register,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
