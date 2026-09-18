import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/utilidades/validators.dart';

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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Simular registro y redirigir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Por favor inicia sesión.'),
          backgroundColor: SmartColors.smartGreen,
        ),
      );
      context.pop(); // Volver al login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Únete a SmartRoute',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: SmartColors.smartText,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tus datos para crear una cuenta',
                  style: TextStyle(
                    fontSize: 14,
                    color: SmartColors.smartGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                CustomTextField(
                  label: 'Nombre completo',
                  hint: 'Ingresa tu nombre',
                  prefixIcon: Icons.badge,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'El nombre es requerido';
                    return null;
                  },
                  onChanged: (val) => _name = val,
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Correo electrónico',
                  hint: 'correo@ejemplo.com',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  onChanged: (val) => _email = val,
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (val) => _password = val,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Selecciona tu rol',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: UserRole.values.map((role) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == role ? SmartColors.smartLightBlue : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == role ? SmartColors.smartBlue : SmartColors.smartBorder,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  _getRoleIcon(role),
                                  color: _selectedRole == role ? SmartColors.smartBlue : SmartColors.smartGray,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.displayName,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: _selectedRole == role ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedRole == role ? SmartColors.smartBlue : SmartColors.smartGray,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Registrarme',
                  icon: Icons.person_add,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.student: return Icons.person;
      case UserRole.admin: return Icons.security;
      case UserRole.driver: return Icons.directions_car;
      case UserRole.owner: return Icons.directions_bus;
    }
  }
}
