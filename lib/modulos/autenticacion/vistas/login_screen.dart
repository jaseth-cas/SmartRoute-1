import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/custom_text_field.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
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
  final TextEditingController _emailController = TextEditingController(text: 'padre@smartroute.com');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123!');
  UserRole selectedRole = UserRole.student;
  bool passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateCredentialsForRole(UserRole role) {
    setState(() {
      selectedRole = role;
      switch (role) {
        case UserRole.student:
          _emailController.text = 'padre@smartroute.com';
          _passwordController.text = 'Password123!';
          break;
        case UserRole.driver:
          _emailController.text = 'conductor@smartroute.com';
          _passwordController.text = 'Password123!';
          break;
        case UserRole.owner:
          _emailController.text = 'dueno@smartroute.com';
          _passwordController.text = 'Password123!';
          break;
      }
    });
  }

  void _enterRole(UserRole role) {
    String customName = _emailController.text;
    if (_emailController.text.contains('@')) {
      customName = _emailController.text.split('@')[0];
      if (customName.isNotEmpty) {
        customName = customName[0].toUpperCase() + customName.substring(1);
      }
    }
    context.read<SessionManager>().login(role, customName: customName);
    switch (role) {
      case UserRole.student:
        context.go('/student_home');
        break;
      case UserRole.driver:
        context.go('/driver_home');
        break;
      case UserRole.owner:
        context.go('/owner_home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideWeb = constraints.maxWidth >= 920;

            if (isWideWeb) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1060),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Columna Izquierda: Showcase Web Corporativo
                        Expanded(
                          flex: 5,
                          child: _buildWebBrandShowcase(),
                        ),
                        const SizedBox(width: 44),
                        // Columna Derecha: Tarjeta de Acceso y Selección de Perfil
                        Expanded(
                          flex: 5,
                          child: NeumorphicBox(
                            padding: const EdgeInsets.all(32),
                            borderRadius: BorderRadius.circular(32),
                            child: _buildLoginForm(isWeb: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // Vista Móvil / Pantallas Angostas
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _buildLoginForm(isWeb: false),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildWebBrandShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: SmartColors.deepBlack,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'PORTAL INSTITUCIONAL // SMARTROUTE WEB',
            style: GoogleFonts.jetBrainsMono(
              color: SmartColors.vibrantCyan,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            NeumorphicBox(
              width: 56,
              height: 56,
              borderRadius: BorderRadius.circular(18),
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SmartRoute',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: SmartColors.deepBlack,
                  ),
                ),
                Text(
                  'SISTEMA INTELIGENTE DE TRANSPORTE ESCOLAR',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: SmartColors.deepBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Monitoreo telemático en tiempo real, biometría facial IA para abordaje y gestión integral de flota escolar.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            height: 1.5,
            color: SmartColors.smartGray,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),

        // 3 Tarjetas de Perfiles del Sistema (Texto Informativo Estático)
        _buildProfileShowcaseCard(
          title: 'Portal de Familia y Tutores',
          desc: 'Telemetría GPS en vivo, alertas de proximidad y reporte de inasistencias.',
          icon: Icons.family_restroom_rounded,
        ),
        const SizedBox(height: 12),
        _buildProfileShowcaseCard(
          title: 'Cabina de Conductor Escolar',
          desc: 'Manifiesto de alumnos, escáner biométrico facial y alerta de incidentes.',
          icon: Icons.airline_seat_recline_normal_rounded,
        ),
        const SizedBox(height: 12),
        _buildProfileShowcaseCard(
          title: 'Panel SaaS de Transportista',
          desc: 'Métricas de flota, control de cobros escolares y despacho de unidades.',
          icon: Icons.business_center_rounded,
        ),
      ],
    );
  }

  Widget _buildProfileShowcaseCard({
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: SmartColors.ghostWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: SmartColors.deepBlue.withValues(alpha: 0.10),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: SmartColors.deepBlue.withValues(alpha: 0.04),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SmartColors.deepBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SmartColors.deepBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: SmartColors.deepBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: SmartColors.smartGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required bool isWeb}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isWeb) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: SmartColors.deepBlack,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AUTH PORTAL // ACCESO SEGURO',
                  style: GoogleFonts.jetBrainsMono(
                    color: SmartColors.vibrantCyan,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: NeumorphicBox(
                width: 72,
                height: 72,
                borderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            'Iniciar Sesión',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isWeb ? 24 : 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: SmartColors.deepBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecciona el perfil de usuario y presiona Ingresar.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: SmartColors.smartGray,
            ),
          ),
          const SizedBox(height: 20),

          // Selector de Perfiles Escolar (Padre / Chofer / Dueño)
          Text(
            'PERFIL DE USUARIO A INGRESAR',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: SmartColors.deepPetrol,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: SmartColors.neuInset,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: SmartColors.deepBlue.withValues(alpha: 0.05),
                  offset: const Offset(1.5, 2),
                  blurRadius: 4,
                ),
                const BoxShadow(
                  color: Colors.white,
                  offset: Offset(-1.5, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: UserRole.values.map((role) {
                final isSelected = selectedRole == role;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateCredentialsForRole(role),
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
          const SizedBox(height: 20),

          // Inputs Neumórficos
          CustomTextField(
            controller: _emailController,
            label: 'Correo Electrónico',
            hint: 'correo@smartroute.com',
            prefixIcon: Icons.alternate_email_rounded,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: !passwordVisible,
            validator: Validators.validatePassword,
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: SmartColors.deepBlue,
                size: 20,
              ),
              onPressed: () => setState(() => passwordVisible = !passwordVisible),
            ),
          ),
          const SizedBox(height: 18),

          // Información de sesión preparada
          NeumorphicBox(
            isInset: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: SmartColors.deepBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Acceso listo para: ${_getRoleDescription(selectedRole)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: SmartColors.deepBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón Único de Ingreso
          PrimaryButton(
            text: _isLoading ? 'INGRESANDO...' : 'INGRESAR AL SISTEMA',
            icon: _isLoading ? Icons.hourglass_top_rounded : Icons.login_rounded,
            enabled: !_isLoading,
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _handleLogin();
              }
            },
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta?',
                style: GoogleFonts.plusJakartaSans(
                  color: SmartColors.smartGray,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  'Registrarse',
                  style: GoogleFonts.plusJakartaSans(
                    color: SmartColors.deepBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Tutor / Padre de Familia';
      case UserRole.driver:
        return 'Chofer de Ruta Escolar';
      case UserRole.owner:
        return 'Dueño de Flota Escolar';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

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
            selectedRole.name;

        final UserRole matchedRole = UserRole.values.firstWhere(
          (r) => r.name == rolStr,
          orElse: () => selectedRole,
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
          content: Text('Supabase offline o credenciales no encontradas: $errorMsg'),
          backgroundColor: SmartColors.smartRed,
          action: SnackBarAction(
            label: 'Acceso Demo',
            textColor: Colors.white,
            onPressed: () => _enterRole(selectedRole),
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
}
