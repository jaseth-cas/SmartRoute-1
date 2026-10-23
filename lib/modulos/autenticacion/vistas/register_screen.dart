import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/utilidades/validators.dart';
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
        email: _email,
        password: _password,
        nombre: _name,
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
        context.pop(); // Volver al login para que el usuario ingrese sus nuevas credenciales
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear credenciales en Supabase: $e'),
          backgroundColor: SmartColors.smartRed,
        ),
      );
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
                  'Crea tus credenciales de acceso para conectarte a Supabase',
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
                  hint: 'correo@smartroute.com',
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  onChanged: (val) => _email = val,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Teléfono / Móvil (opcional)',
                  hint: '+57 300 123 4567',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  onChanged: (val) => _phone = val,
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Contraseña',
                  hint: 'Mínimo 6 caracteres',
                  prefixIcon: Icons.lock,
                  isPassword: true,
                  validator: Validators.validatePassword,
                  onChanged: (val) => _password = val,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Confirmar Contraseña',
                  hint: 'Repite tu contraseña',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirma tu contraseña';
                    if (val != _password) return 'Las contraseñas no coinciden';
                    return null;
                  },
                  onChanged: (val) => _confirmPassword = val,
                ),
                const SizedBox(height: 24),

                const Text(
                  'Selecciona tu rol en la plataforma',
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
                  text: _isLoading ? 'Creando credenciales...' : 'Crear Cuenta',
                  icon: _isLoading ? Icons.hourglass_top : Icons.person_add,
                  enabled: !_isLoading,
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
      case UserRole.driver: return Icons.directions_car;
      case UserRole.owner: return Icons.directions_bus;
    }
  }
}
