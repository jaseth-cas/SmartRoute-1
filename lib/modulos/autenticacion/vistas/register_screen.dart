import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/custom_text_field.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';
  String _confirmPassword = '';
  UserRole _selectedRole = UserRole.student;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_password.trim().isEmpty) return;

    if (_password != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden. Por favor verifícalas.'),
          backgroundColor: SmartColors.smartRed,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.signUp(
        email: _email.trim(),
        password: _password.trim(),
        nombre: _name.trim(),
        rol: _selectedRole,
        telefono: _phone.trim().isNotEmpty ? _phone.trim() : null,
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Credenciales creadas para ${_selectedRole.displayName}! Ya puedes iniciar sesión.',
            ),
            backgroundColor: SmartColors.smartGreen,
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo completar el registro. Verifica los datos e intenta de nuevo.'),
            backgroundColor: SmartColors.smartRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Aviso Supabase register: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aviso Supabase: $e. Registrando en modo demo local.'),
          backgroundColor: SmartColors.deepBlue,
          duration: const Duration(seconds: 3),
        ),
      );
      context.pop();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: SmartColors.neuInset,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: UserRole.values.map((role) {
                          final isSelected = _selectedRole == role;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedRole = role),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? SmartColors.deepBlack : Colors.transparent,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: SmartColors.deepBlack.withValues(alpha: 0.25),
                                            offset: const Offset(0, 3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  role == UserRole.student
                                      ? 'PADRE'
                                      : role == UserRole.driver
                                          ? 'CHOFER'
                                          : 'DUEÑO',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isSelected ? SmartColors.ghostWhite : SmartColors.smartGray,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
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
                      label: 'Teléfono / Móvil (opcional)',
                      hint: '+57 300 123 4567',
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => _phone = val,
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
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Confirmar Contraseña',
                      hint: 'Repite tu contraseña',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                        if (val != _password) return 'Las contraseñas no coinciden';
                        return null;
                      },
                      onChanged: (val) => _confirmPassword = val,
                    ),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      text: _isLoading ? 'CREANDO REGISTRO...' : 'COMPLETAR REGISTRO',
                      icon: _isLoading ? Icons.hourglass_top_rounded : Icons.check_circle_outline_rounded,
                      enabled: !_isLoading,
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
