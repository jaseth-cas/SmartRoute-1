import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../autenticacion/datos/session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _studentNameCtrl;
  late final TextEditingController _pickupAddressCtrl;
  late final TextEditingController _schoolCtrl;

  late StudentPassengerMock _student;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionManager>().currentSession;
    _student = MockData.getPrimaryStudent();

    _nameCtrl = TextEditingController(text: session?.name ?? _student.parentName);
    _emailCtrl = TextEditingController(text: session?.email ?? 'padre@smartroute.com');
    _phoneCtrl = TextEditingController(text: _student.parentPhone);
    _studentNameCtrl = TextEditingController(text: _student.name);
    _pickupAddressCtrl = TextEditingController(text: _student.pickupAddress);
    _schoolCtrl = TextEditingController(text: _student.schoolName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
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
        name: _nameCtrl.text,
        email: _emailCtrl.text,
      );

      // 2. Actualizar perfil del padre en Supabase si hay sesión activa
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId != null) {
        await authService.updateUserProfile(
          userId: currentUserId,
          nombre: _nameCtrl.text,
          email: _emailCtrl.text,
          telefono: _phoneCtrl.text,
        );
      }

      // 3. Actualizar datos del estudiante representado (RF-02)
      await studentService.updateStudentProfile(
        studentId: _student.id,
        name: _studentNameCtrl.text,
        pickupAddress: _pickupAddressCtrl.text,
        parentPhone: _phoneCtrl.text,
        schoolName: _schoolCtrl.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil del tutor y estudiante actualizado exitosamente'),
            backgroundColor: SmartColors.smartGreen,
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
      backgroundColor: SmartColors.smartBackground,
      appBar: AppBar(
        title: const Text('Editar Perfil y Estudiante', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/student_profile');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: SmartColors.smartLightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, size: 60, color: SmartColors.smartBlue),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: SmartColors.smartBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datos del Padre / Tutor Legal',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SmartColors.smartBlue),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nombre completo',
                hint: 'Ingresa tu nombre',
                prefixIcon: Icons.badge,
                controller: _nameCtrl,
                validator: (val) => Validators.validateRequired(val, fieldName: 'El nombre'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Correo electrónico',
                hint: 'padre.familia@smartroute.com',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Teléfono de emergencia',
                hint: 'Tu número de teléfono',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                controller: _phoneCtrl,
                validator: (val) => Validators.validatePhone(val, required: true),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Datos del Estudiante Asociado (RF-02)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SmartColors.smartBlue),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nombre del Estudiante',
                hint: 'Nombre de tu hijo(a)',
                prefixIcon: Icons.child_care,
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
                text: 'Guardar cambios',
                icon: Icons.save,
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
