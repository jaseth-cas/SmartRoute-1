import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/modelos/models.dart';
import '../../../nucleo/servicios/auth_service.dart';
import '../../../nucleo/servicios/bus_service.dart';
import '../../../nucleo/servicios/student_service.dart';
import '../../../nucleo/servicios/supabase_client.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/utilidades/validators.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/neumorphic_box.dart';
import '../../../nucleo/widgets/responsive_layout.dart';
import '../../../nucleo/widgets/school_selector_field.dart';
import '../../../nucleo/utilidades/coordinate_parser.dart';
import 'package:latlong2/latlong.dart';
import '../../autenticacion/datos/session_manager.dart';
import 'student_location_picker_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _studentNameCtrl;
  late final TextEditingController _pickupAddressCtrl;
  late final TextEditingController _schoolCtrl;

  StudentPassengerMock? _student;
  double? _pendingLat;
  double? _pendingLng;
  bool _isLoading = true;
  bool _isSaving = false;
  StreamSubscription<StudentPassengerMock>? _locationSub;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionManager>().currentSession;

    _nameController = TextEditingController(text: session?.name ?? '');
    _emailController = TextEditingController(text: session?.email ?? '');
    _phoneController = TextEditingController();
    _studentNameCtrl = TextEditingController();
    _pickupAddressCtrl = TextEditingController();
    _schoolCtrl = TextEditingController();

    _locationSub = StudentService.locationUpdatesStream.listen((updated) {
      if (!mounted) return;
      if (_student == null || updated.id == _student!.id) {
        setState(() {
          _student = updated;
          if (_pickupAddressCtrl.text.trim().isEmpty ||
              _pickupAddressCtrl.text != updated.pickupAddress) {
            _pickupAddressCtrl.text = updated.pickupAddress;
          }
        });
      }
    });

    _loadInitialProfile();
  }

  /// GET inicial: carga el perfil de tutor y los datos del estudiante desde Supabase
  /// y pre-rellena todos los campos del formulario.
  Future<void> _loadInitialProfile() async {
    try {
      final session = context.read<SessionManager>().currentSession;
      final studentService = context.read<StudentService>();
      final userId = SupabaseConfig.client.auth.currentUser?.id ?? session?.userId;

      final results = await Future.wait([
        studentService.getPrimaryStudent(userId),
        if (userId != null && userId.isNotEmpty)
          studentService.getParentProfileById(userId)
        else
          Future<Map<String, dynamic>?>.value(null),
      ]);

      final student = results[0] as StudentPassengerMock?;
      final profile = results[1] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _student = student;
        if (profile != null) {
          _nameController.text = profile['nombre']?.toString() ?? _nameController.text;
          _emailController.text = profile['email']?.toString() ?? _emailController.text;
          _phoneController.text = profile['telefono']?.toString() ?? (student?.parentPhone ?? '');
        } else if (student != null) {
          if (_nameController.text.isEmpty) _nameController.text = student.parentName;
          _phoneController.text = student.parentPhone;
        }
        if (student != null) {
          _studentNameCtrl.text = student.name;
          _pickupAddressCtrl.text = student.pickupAddress;
          _schoolCtrl.text = student.schoolName;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando perfil en EditProfileScreen: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentNameCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      final sessionManager = context.read<SessionManager>();
      final authService = context.read<AuthService>();
      final studentService = context.read<StudentService>();
      final busService = context.read<BusService>();

      // 1. Actualizar sesión activa en memoria
      sessionManager.updateUserInfo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // 2. Actualizar perfil del padre en Supabase verificando sesión activa
      final currentUserId =
          SupabaseConfig.client.auth.currentUser?.id ?? sessionManager.currentSession?.userId;
      if (currentUserId == null || currentUserId.trim().isEmpty) {
        throw StateError(
          'No hay una sesión de usuario activa para guardar los datos del tutor.',
        );
      }

      await authService.updateUserProfile(
        userId: currentUserId,
        nombre: _nameController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _phoneController.text.trim(),
      );

      // 3. PUT unificado del estudiante o matrícula si es padre nuevo sin estudiante asignado
      StudentPassengerMock? targetStudent = _student;
      if (targetStudent == null || targetStudent.id <= 0) {
        targetStudent = await studentService.getPrimaryStudent(currentUserId);
      }

      if (targetStudent != null && targetStudent.id > 0) {
        final updated = await studentService.updateStudent(
          studentId: targetStudent.id,
          name: _studentNameCtrl.text.trim(),
          parentName: _nameController.text.trim(),
          parentPhone: _phoneController.text.trim(),
          pickupAddress: _pickupAddressCtrl.text.trim(),
          schoolName: _schoolCtrl.text.trim(),
          pickupLatitude: _pendingLat,
          pickupLongitude: _pendingLng,
        );
        if (updated == null) {
          throw StateError(
            'No se pudo actualizar el registro del estudiante en PostgreSQL.',
          );
        }
        if (mounted) {
          _student = updated;
        }
      } else {
        final buses = await busService.getAllBuses();
        final availableBus = buses.where((b) => b.hasAvailableSeats).firstOrNull ?? buses.firstOrNull;
        if (availableBus == null) {
          throw StateError(
            'No se pudo conectar con Supabase o no hay autobuses disponibles para matricular al estudiante.',
          );
        }
        _student = await studentService.enrollStudent(
          name: _studentNameCtrl.text.trim(),
          parentName: _nameController.text.trim(),
          parentPhone: _phoneController.text.trim(),
          pickupAddress: _pickupAddressCtrl.text.trim(),
          bus: availableBus,
          schoolName: _schoolCtrl.text.trim(),
          parentId: currentUserId,
          pickupLatitude: _pendingLat,
          pickupLongitude: _pendingLng,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil de tutor y estudiante actualizado con éxito.'),
            backgroundColor: SmartColors.deepBlue,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/student_profile');
        }
      }
    } catch (e) {
      if (mounted) {
        final raw = e.toString();
        final msg = raw.contains('SocketException') ||
                raw.contains('Connection refused') ||
                raw.contains('54321')
            ? 'Sin conexión con Supabase (127.0.0.1:54321). Verifica que el túnel USB (adb reverse tcp:54321 tcp:54321) esté activo.'
            : 'Error guardando cambios: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: SmartColors.primaryCrimson,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/student_profile');
                }
              },
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
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
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
                  validator: (val) => Validators.validateRequired(val, fieldName: 'El nombre'),
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
                  validator: (val) => Validators.validatePhone(val, required: true),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nombre del Estudiante',
                  hint: 'Nombre de tu hijo(a)',
                  prefixIcon: Icons.child_care_rounded,
                  controller: _studentNameCtrl,
                  validator: (val) => Validators.validateRequired(val, fieldName: 'El nombre del estudiante'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Dirección exacta de recogida / retorno',
                  hint: 'Calle y número de residencia',
                  prefixIcon: Icons.home_outlined,
                  controller: _pickupAddressCtrl,
                  validator: (val) => Validators.validateRequired(val, fieldName: 'La dirección de recogida'),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: (_student?.pickupLatitude != null && _student?.pickupLongitude != null)
                      ? 'MAPA GPS (${CoordinateParser.formatDd(LatLng(_student!.pickupLatitude!, _student!.pickupLongitude!))})'
                      : 'SELECCIONAR UBICACIÓN EN MAPA',
                  icon: Icons.add_location_alt_rounded,
                  isCyan: true,
                  onPressed: () async {
                    final picked = await StudentLocationPickerScreen.open(
                      context,
                      student: _student,
                      initialCoordinates: (_student?.pickupLatitude != null &&
                              _student?.pickupLongitude != null)
                          ? LatLng(_student!.pickupLatitude!, _student!.pickupLongitude!)
                          : null,
                      initialAddress: _pickupAddressCtrl.text,
                    );
                    if (picked != null && mounted) {
                      setState(() {
                        _pendingLat = picked.homePoint.latitude;
                        _pendingLng = picked.homePoint.longitude;
                        if (_student != null) {
                          _student = _student!.copyWith(
                            pickupLatitude: picked.homePoint.latitude,
                            pickupLongitude: picked.homePoint.longitude,
                            pickupAddress: picked.addressLabel,
                          );
                        }
                        _pickupAddressCtrl.text = picked.addressLabel;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SchoolSelectorField(
                  label: 'Colegio de destino',
                  initialValue: _schoolCtrl.text,
                  onChanged: (val) => _schoolCtrl.text = val,
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: _isSaving ? 'GUARDANDO...' : 'GUARDAR CAMBIOS',
                  icon: Icons.check_circle_outline_rounded,
                  enabled: !_isSaving,
                  onPressed: _saveProfile,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
