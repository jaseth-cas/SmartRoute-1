import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/student_location_picker_screen.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
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
  final AuthService _authService = AuthService();

  String _name = '';
  String _email = '';
  final String _phone = '';
  String _password = '';
  UserRole _selectedRole = UserRole.student;
  bool _passwordVisible = false;
  bool _isLoading = false;

  Future<StudentPassengerMock?> _ensureStudentCreatedForPicker(String? parentId) async {
    final cleanName = _name.trim().isNotEmpty ? _name.trim() : 'Nuevo Estudiante';
    try {
      final studentService = context.read<StudentService>();
      final busService = context.read<BusService>();

      if (parentId != null && parentId.isNotEmpty) {
        final existing = await studentService.getStudentsByParent(parentId);
        if (existing.isNotEmpty) return existing.first;
      }

      final buses = await busService.getAllBuses();
      final availableBus = buses.where((b) => b.hasAvailableSeats).firstOrNull ??
          buses.firstOrNull;
      if (availableBus == null) return null;

      return await studentService.enrollStudent(
        name: cleanName,
        parentName: '$cleanName (Tutor)',
        parentPhone: _phone.trim().isNotEmpty ? _phone.trim() : '+507 6000-0000',
        pickupAddress: 'Penonomé, Coclé',
        bus: availableBus,
        schoolName: availableBus.schoolName ?? 'Colegio Ángel María Herrera',
        parentId: parentId,
        pickupLatitude: AppConstants.penonomeCenter.latitude,
        pickupLongitude: AppConstants.penonomeCenter.longitude,
      );
    } catch (e) {
      debugPrint('Error creando estudiante en registro: $e');
      return null;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _password.trim().isEmpty) return;
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
        if (_selectedRole == UserRole.student) {
          final createdStudent =
              await _ensureStudentCreatedForPicker(response.user!.id);
          if (!mounted) return;
          if (createdStudent != null) {
            await StudentLocationPickerScreen.open(
              context,
              student: createdStudent,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cuenta creada, pero no se pudo matricular automáticamente al estudiante en un autobús. Complétalo en Editar Perfil.',
                ),
                backgroundColor: SmartColors.smartRed,
                duration: Duration(seconds: 5),
              ),
            );
          }
          if (!mounted) return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Credenciales creadas para ${_selectedRole.displayName}! Ya puedes iniciar sesión.',
            ),
            backgroundColor: SmartColors.deepBlue,
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
        return;
      }
      throw StateError('No se pudo registrar el usuario en Supabase.');
    } catch (e) {
      debugPrint('Error en Supabase signUp: $e');
      if (mounted) {
        final raw = e.toString();
        final String msg;
        if (raw.contains('SocketException') ||
            raw.contains('Connection refused') ||
            raw.contains('54321') ||
            raw.contains('TimeoutException')) {
          msg =
              'Sin conexión con Supabase (127.0.0.1:54321). Verifica Docker o ejecuta: adb reverse tcp:54321 tcp:54321.';
        } else if (raw.contains('already registered') ||
            raw.contains('user_already_exists') ||
            raw.contains('422') ||
            raw.contains('409')) {
          msg = 'Ya existe una cuenta registrada con ese correo electrónico.';
        } else {
          msg = 'No se pudo crear la cuenta: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: SmartColors.smartRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: SmartColors.deepBlack,
              ),
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
                        if (val == null || val.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
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
                      isPassword: !_passwordVisible,
                      validator: Validators.validatePassword,
                      onChanged: (val) => _password = val,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: SmartColors.deepBlue,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _passwordVisible = !_passwordVisible),
                      ),
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
                      text: _isLoading ? 'CREANDO CUENTA...' : 'COMPLETAR REGISTRO',
                      icon: Icons.check_circle_outline_rounded,
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
