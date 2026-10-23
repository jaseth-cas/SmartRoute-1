import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  String email = "";
  String password = "";
  bool passwordVisible = false;
  bool _isLoading = false;

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
                      hintText: 'correo@smartroute.com',
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
              const SizedBox(height: 16),
              // Backend Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SmartColors.smartLightGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartColors.smartGreen.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_done, color: SmartColors.smartGreen, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Supabase Local Activo (Docker)',
                            style: TextStyle(
                              fontSize: 13,
                              color: SmartColors.smartGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Auth PostgreSQL + Realtime sincronizado por ADB',
                            style: TextStyle(
                              fontSize: 11,
                              color: SmartColors.smartGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
                icon: _isLoading ? Icons.hourglass_top : Icons.lock,
                enabled: !_isLoading,
                onPressed: _handleLogin,
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Iniciar sesión real en el servidor Supabase (Docker)
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (!mounted) return;

      if (user != null && session != null) {
        // Consultar el perfil y rol registrado en PostgreSQL
        final profile = await _authService.fetchUserProfile(user.id);
        if (!mounted) return;

        final String nombre = profile?['nombre'] ??
            user.userMetadata?['nombre'] ??
            (email.contains('@') ? email.split('@')[0] : email);

        final String rolStr = profile?['rol'] ??
            user.userMetadata?['rol'] ??
            'student';

        final UserRole matchedRole = UserRole.values.firstWhere(
          (r) => r.name == rolStr,
          orElse: () => UserRole.student,
        );

        context.read<SessionManager>().loginWithSupabase(
              userId: user.id,
              name: nombre,
              email: user.email ?? email,
              role: matchedRole,
              token: session.accessToken,
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión iniciada: $nombre (${matchedRole.displayName})'),
            backgroundColor: SmartColors.smartGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        widget.onLoginSuccess();
        return;
      }
    } catch (e) {
      debugPrint('Aviso Supabase login: $e');
      if (!mounted) return;

      final errorMsg = e.toString().replaceAll('AuthException', '').replaceAll(':', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credenciales no encontradas en Supabase: $errorMsg'),
          backgroundColor: SmartColors.smartRed,
          action: SnackBarAction(
            label: 'Acceso Demo',
            textColor: Colors.white,
            onPressed: _loginMockDemo,
          ),
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

  void _loginMockDemo() {
    String customName = email;
    if (email.contains('@')) {
      customName = email.split('@')[0];
      if (customName.isNotEmpty) {
        customName = customName[0].toUpperCase() + customName.substring(1);
      }
    }
    UserRole fallbackRole = UserRole.student;
    if (email.contains('conductor') || email.contains('driver')) {
      fallbackRole = UserRole.driver;
    } else if (email.contains('transportista') ||
        email.contains('owner') ||
        email.contains('flota')) {
      fallbackRole = UserRole.owner;
    }
    context.read<SessionManager>().login(fallbackRole, customName: customName);
    widget.onLoginSuccess();
  }
}
