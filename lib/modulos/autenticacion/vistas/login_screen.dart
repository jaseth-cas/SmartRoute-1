import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = "";
  String password = "";
  bool passwordVisible = false;
  UserRole selectedRole = UserRole.student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/logo2.png', width: 40, fit: BoxFit.contain),
                  const SizedBox(width: 12),
                  const Text(
                    'SmartRoute',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: SmartColors.smartBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const Text(
                'Inicia sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: SmartColors.smartText,
                ),
              ),
              const Text(
                'Accede a tu cuenta para continuar',
                style: TextStyle(
                  fontSize: 14,
                  color: SmartColors.smartGray,
                ),
              ),
              const SizedBox(height: 32),
              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correo o usuario',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) => email = value,
                    validator: Validators.validateEmail,
                    decoration: InputDecoration(
                      hintText: 'correo@universidad.edu',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contraseña',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) => password = value,
                    validator: Validators.validatePassword,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona tu rol',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: UserRole.values.map((role) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: RoleItem(
                        role: role,
                        isSelected: selectedRole == role,
                        onClick: () {
                          setState(() {
                            selectedRole = role;
                          });
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              // Simulated JWT Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SmartColors.smartLightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartColors.smartGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: SmartColors.smartGreen, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Autenticación simulada mediante JWT local',
                        style: TextStyle(
                          fontSize: 13,
                          color: SmartColors.smartGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Iniciar sesión',
                icon: Icons.lock,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<SessionManager>().login(selectedRole);
                    widget.onLoginSuccess();
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes cuenta?',
                    style: TextStyle(color: SmartColors.smartGray, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        color: SmartColors.smartBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Olvidé mi contraseña',
                  style: TextStyle(
                    color: SmartColors.smartGray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoleItem extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onClick;

  const RoleItem({
    super.key,
    required this.role,
    required this.isSelected,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (role) {
      case UserRole.student:
        icon = Icons.person;
        break;
      case UserRole.admin:
        icon = Icons.security;
        break;
      case UserRole.driver:
        icon = Icons.directions_car;
        break;
      case UserRole.owner:
        icon = Icons.directions_bus;
        break;
    }

    return GestureDetector(
      onTap: onClick,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? SmartColors.smartLightBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? SmartColors.smartBlue : SmartColors.smartBorder,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? SmartColors.smartBlue : SmartColors.smartGray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? SmartColors.smartBlue : SmartColors.smartGray,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
