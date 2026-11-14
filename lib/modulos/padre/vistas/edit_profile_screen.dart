import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../nucleo/datos/mock_data.dart';
import '../../../nucleo/modelos/models.dart';
import '../../../nucleo/servicios/auth_service.dart';
import '../../../nucleo/servicios/student_service.dart';
import '../../../nucleo/servicios/supabase_client.dart';
import '../../../nucleo/tema/colors.dart';
import '../../../nucleo/utilidades/validators.dart';
import '../../../nucleo/widgets/custom_text_field.dart';
import '../../../nucleo/widgets/primary_button.dart';
import '../../../nucleo/widgets/neumorphic_box.dart';
import '../../../nucleo/widgets/responsive_layout.dart';
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

  late StudentPassengerMock _student;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionManager>().currentSession;
    _student = MockData.getPrimaryStudent();

    _nameController = TextEditingController(text: session?.name ?? _student.parentName);
    _emailController = TextEditingController(text: session?.email ?? 'carlos.gomez@smartroute.com');
    _phoneController = TextEditingController(text: _student.parentPhone);
    _studentNameCtrl = TextEditingController(text: _student.name);
    _pickupAddressCtrl = TextEditingController(text: _student.pickupAddress);
    _schoolCtrl = TextEditingController(text: _student.schoolName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentNameCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _schoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final sessionManager = context.read<SessionManager>();
      final authService = context.read<AuthService>();
      final studentService = context.read<StudentService>();

      // 1. Actualizar sesión activa en memoria
      sessionManager.updateUserInfo(
        name: _nameController.text,
        email: _emailController.text,
      );

      // 2. Actualizar perfil del padre en Supabase si hay sesión activa
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId != null) {
        await authService.updateUserProfile(
          userId: currentUserId,
          nombre: _nameController.text,
          email: _emailController.text,
          telefono: _phoneController.text,
        );
      }

      // 3. Actualizar datos del estudiante representado (RF-02)
      await studentService.updateStudentProfile(
        studentId: _student.id,
        name: _studentNameCtrl.text,
        pickupAddress: _pickupAddressCtrl.text,
        parentPhone: _phoneController.text,
        schoolName: _schoolCtrl.text,
      );

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
                  text: _student.pickupLatitude != null && _student.pickupLongitude != null
                      ? 'MAPA GPS / COORDENADAS (${CoordinateParser.formatDd(LatLng(_student.pickupLatitude!, _student.pickupLongitude!))})'
                      : 'SELECCIONAR UBICACIÓN EN MAPA (GPS / DD / DMS)',
                  icon: Icons.add_location_alt_rounded,
                  isCyan: true,
                  onPressed: () async {
                    final picked = await StudentLocationPickerScreen.open(
                      context,
                      student: _student,
                      initialAddress: _pickupAddressCtrl.text,
                    );
                    if (picked != null && mounted) {
                      setState(() {
                        _student = _student.copyWith(
                          pickupLatitude: picked.homePoint.latitude,
                          pickupLongitude: picked.homePoint.longitude,
                          pickupAddress: picked.addressLabel,
                        );
                        _pickupAddressCtrl.text = picked.addressLabel;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Colegio de destino',
                  hint: 'Colegio San José',
                  prefixIcon: Icons.school_outlined,
                  controller: _schoolCtrl,
                  validator: (val) => Validators.validateRequired(val, fieldName: 'El colegio'),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'GUARDAR CAMBIOS',
                  icon: Icons.check_circle_outline_rounded,
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
