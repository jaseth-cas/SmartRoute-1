import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/modulos/padre/vistas/student_location_picker_screen.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/auth_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';
import 'package:smartroute_flutter/nucleo/widgets/school_selector_field.dart';
import 'package:smartroute_flutter/nucleo/widgets/trust_safety_dialog.dart';
import 'package:smartroute_flutter/nucleo/widgets/user_options_bar.dart';
import 'package:smartroute_flutter/nucleo/vistas/transit_loading_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List<BusMock> _buses = [];
  List<StudentPassengerMock> _passengers = [];
  FleetFinancialSummary _financialSummary = FleetFinancialSummary.empty;
  bool _isLoading = true;
  StreamSubscription<StudentPassengerMock>? _locationSub;
  RealtimeChannel? _studentsRealtimeChannel;
  StudentService? _studentService;

  @override
  void initState() {
    super.initState();
    _locationSub = StudentService.locationUpdatesStream.listen((_) {
      if (mounted) _loadFleetData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFleetData();
      try {
        final studentService = context.read<StudentService>();
        _studentService = studentService;
        _studentsRealtimeChannel = studentService.subscribeToStudentChanges(
          channelName: 'owner_home_estudiantes_${DateTime.now().millisecondsSinceEpoch}',
          onChanged: () {
            if (mounted) _loadFleetData();
          },
        );
      } catch (e) {
        debugPrint('Aviso suscribiendo Realtime en OwnerHomeScreen: $e');
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _studentService?.unsubscribeChannel(_studentsRealtimeChannel);
    super.dispose();
  }

  Future<void> _loadFleetData() async {
    setState(() => _isLoading = true);
    final busService = context.read<BusService>();
    final studentService = context.read<StudentService>();

    try {
      final busesFuture = busService.getAllBuses();
      final summaryFuture = studentService.getFleetFinancialSummary();
      final studentsFuture = studentService.getAllStudents();

      final results = await Future.wait([busesFuture, summaryFuture, studentsFuture]);

      if (mounted) {
        setState(() {
          _buses = results[0] as List<BusMock>;
          _financialSummary = results[1] as FleetFinancialSummary;
          _passengers = results[2] as List<StudentPassengerMock>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos de flota en OwnerHomeScreen: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToRegisterBus() async {
    final result = await context.push<bool>('/register_bus');
    if (result == true) {
      await _loadFleetData();
    }
  }

  /* [DESHABILITADO TEMPORALMENTE] Pasarela de pago / control de cobros aún no contemplada.
  Future<void> _cyclePaymentStatus(StudentPassengerMock student) async {
    final nextStatus = switch (student.paymentStatus) {
      'Al día' => 'Pendiente',
      'Pendiente' => 'En mora',
      _ => 'Al día',
    };

    final studentService = context.read<StudentService>();
    await studentService.updatePaymentStatus(
      studentId: student.id,
      status: nextStatus,
    );
    await _loadFleetData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de pago de ${student.name}: $nextStatus'),
        backgroundColor: nextStatus == 'Al día' ? SmartColors.smartGreen : SmartColors.smartRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  */

  Future<void> _showEnrollStudentDialog() async {
    final activeBuses = _buses;
    if (activeBuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registra primero al menos un autobús en la flota.'),
          backgroundColor: SmartColors.smartRed,
        ),
      );
      return;
    }

    final studentService = context.read<StudentService>();
    List<StudentPassengerMock> catalog = List<StudentPassengerMock>.from(_passengers);
    try {
      final fetched = await studentService.getSearchableStudentsCatalog();
      if (fetched.isNotEmpty) catalog = fetched;
    } catch (_) {}

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final searchController = TextEditingController();
    final parentNameController = TextEditingController();
    final parentPhoneController = TextEditingController();
    final pickupAddressController = TextEditingController();

    StudentPassengerMock? selectedExistingStudent;
    bool isDropdownOpen = true;
    bool openMapAfterAssign = false;
    BusMock selectedBus = activeBuses.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final hasSeats = selectedBus.hasAvailableSeats;
          final query = searchController.text.trim().toLowerCase();

          final filteredStudents = catalog.where((s) {
            if (query.isEmpty) return true;
            return s.name.toLowerCase().contains(query) ||
                s.parentName.toLowerCase().contains(query) ||
                s.pickupAddress.toLowerCase().contains(query) ||
                s.busCode.toLowerCase().contains(query);
          }).toList();

          void selectStudentFromList(StudentPassengerMock student) {
            setDialogState(() {
              selectedExistingStudent = student;
              searchController.text = student.name;
              searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: searchController.text.length),
              );
              parentNameController.text = student.parentName;
              parentPhoneController.text = student.parentPhone;
              pickupAddressController.text = student.pickupAddress;
              openMapAfterAssign = student.pickupLatitude == null || student.pickupLongitude == null;
              isDropdownOpen = false;
            });
          }

          return AlertDialog(
            backgroundColor: SmartColors.neuSurface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'ASIGNAR CUPO ESCOLAR (RF-05)',
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: SmartColors.deepBlack,
                letterSpacing: 0.6,
              ),
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Selector de Autobús Escolar
                      DropdownButtonFormField<String>(
                        initialValue: selectedBus.code,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Autobús Escolar Destino',
                          prefixIcon: const Icon(Icons.directions_bus_rounded, color: SmartColors.deepBlue, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: activeBuses.map((b) {
                          return DropdownMenuItem(
                            value: b.code,
                            child: Text(
                              '${b.code} (${b.seatsOccupied}/${b.capacity} cupos)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (code) {
                          if (code != null) {
                            setDialogState(() {
                              selectedBus = activeBuses.firstWhere((b) => b.code == code);
                            });
                          }
                        },
                      ),
                      if (!hasSeats) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Esta unidad no tiene asientos libres disponibles (Sobrecupo bloqueado).',
                          style: TextStyle(color: SmartColors.smartRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 14),

                      // 2. Select con Búsqueda Avanzada de Estudiante
                      TextFormField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar y Seleccionar Estudiante',
                          hintText: 'Escribe ej. "jase", "mateo"...',
                          prefixIcon: const Icon(Icons.person_search_rounded, color: SmartColors.deepBlue),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (searchController.text.isNotEmpty)
                                IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: SmartColors.smartGray),
                                  onPressed: () {
                                    setDialogState(() {
                                      searchController.clear();
                                      selectedExistingStudent = null;
                                      isDropdownOpen = true;
                                    });
                                  },
                                ),
                              IconButton(
                                tooltip: isDropdownOpen ? 'Ocultar lista' : 'Desplegar lista de estudiantes',
                                icon: Icon(
                                  isDropdownOpen
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: SmartColors.deepBlack,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    isDropdownOpen = !isDropdownOpen;
                                  });
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'El estudiante'),
                        onTap: () {
                          setDialogState(() {
                            isDropdownOpen = true;
                          });
                        },
                        onChanged: (v) {
                          setDialogState(() {
                            isDropdownOpen = true;
                            if (selectedExistingStudent != null &&
                                selectedExistingStudent!.name.toLowerCase() != v.trim().toLowerCase()) {
                              selectedExistingStudent = null;
                            }
                          });
                        },
                      ),

                      // Lista Desplegable del Select con Búsqueda Avanzada
                      if (isDropdownOpen) ...[
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 185),
                          decoration: BoxDecoration(
                            color: SmartColors.neuBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: SmartColors.deepBlue.withValues(alpha: 0.22),
                              width: 1.2,
                            ),
                          ),
                          child: filteredStudents.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_add_alt_1_rounded, size: 18, color: SmartColors.deepBlue),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Sin coincidencias en lista. Se registrará a "${searchController.text.trim()}" como nuevo estudiante.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: SmartColors.deepPetrol,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: filteredStudents.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 1,
                                    color: SmartColors.neuBorder.withValues(alpha: 0.6),
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = filteredStudents[index];
                                    final isSelected = selectedExistingStudent?.id == item.id;
                                    final hasGps = item.pickupLatitude != null && item.pickupLongitude != null;

                                    return InkWell(
                                      onTap: () => selectStudentFromList(item),
                                      child: Container(
                                        color: isSelected
                                            ? SmartColors.vibrantCyan.withValues(alpha: 0.14)
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 15,
                                              backgroundColor: isSelected
                                                  ? SmartColors.deepBlack
                                                  : SmartColors.deepBlue.withValues(alpha: 0.12),
                                              child: Text(
                                                item.name.isNotEmpty ? item.name[0].toUpperCase() : 'E',
                                                style: GoogleFonts.jetBrainsMono(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: isSelected
                                                      ? SmartColors.vibrantCyan
                                                      : SmartColors.deepBlue,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          item.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.w800,
                                                            color: SmartColors.deepBlack,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: SmartColors.deepBlack,
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                        child: Text(
                                                          item.busCode,
                                                          style: GoogleFonts.jetBrainsMono(
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.w800,
                                                            color: SmartColors.vibrantCyan,
                                                          ),
                                                        ),
                                                      ),
                                                      if (hasGps) ...[
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons.location_on_rounded,
                                                          size: 13,
                                                          color: SmartColors.smartGreen,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Tutor: ${item.parentName} • ${item.pickupAddress}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 10.5,
                                                      color: SmartColors.smartGray,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: SmartColors.smartGreen,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],

                      if (selectedExistingStudent != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 15, color: SmartColors.smartGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  selectedExistingStudent!.pickupLatitude != null
                                      ? 'Estudiante seleccionado con ubicación GPS ya vinculada.'
                                      : 'Estudiante seleccionado. Sus datos se autocompletaron.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: SmartColors.smartGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: parentNameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Padre / Tutor',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'El tutor'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: parentPhoneController,
                        decoration: InputDecoration(
                          labelText: 'Teléfono de Emergencia',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (v) => Validators.validatePhone(v, required: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pickupAddressController,
                        decoration: InputDecoration(
                          labelText: 'Dirección de Recogida',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => Validators.validateRequired(v, fieldName: 'La dirección'),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: SmartColors.deepBlue,
                        value: openMapAfterAssign,
                        title: Text(
                          'Abrir mapa GPS / coordenadas al guardar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            openMapAfterAssign = val ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'CANCELAR',
                  style: GoogleFonts.jetBrainsMono(
                    color: SmartColors.deepPetrol,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: SmartColors.deepBlack,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: !hasSeats
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final finalStudentName = searchController.text.trim();
                        final finalParentName = parentNameController.text.trim();
                        final finalParentPhone = parentPhoneController.text.trim();
                        final finalPickupAddress = pickupAddressController.text.trim();
                        Navigator.pop(ctx);
                        try {
                          final assignedStudent = await studentService.assignOrEnrollStudent(
                            existingStudent: selectedExistingStudent,
                            name: finalStudentName,
                            parentName: finalParentName,
                            parentPhone: finalParentPhone,
                            pickupAddress: finalPickupAddress,
                            bus: selectedBus,
                            schoolName: selectedExistingStudent?.schoolName.trim().isNotEmpty == true
                                ? selectedExistingStudent!.schoolName
                                : (selectedBus.schoolName != null &&
                                        selectedBus.schoolName!.toLowerCase() != 'múltiples colegios'
                                    ? selectedBus.schoolName!
                                    : 'Colegio Ángel María Herrera'),
                            parentId: selectedExistingStudent?.parentId,
                          );
                          if (mounted &&
                              (openMapAfterAssign ||
                                  assignedStudent.pickupLatitude == null ||
                                  assignedStudent.pickupLongitude == null)) {
                            await StudentLocationPickerScreen.open(
                              context,
                              student: assignedStudent,
                              initialAddress: finalPickupAddress,
                            );
                          }
                          await _loadFleetData();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Estudiante ${assignedStudent.name} asignado a ${selectedBus.code}'),
                              backgroundColor: SmartColors.smartGreen,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$e'),
                              backgroundColor: SmartColors.smartRed,
                            ),
                          );
                        }
                      },
                child: Text(
                  'ASIGNAR ASIENTO',
                  style: GoogleFonts.jetBrainsMono(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionManager = context.watch<SessionManager>();
    final session = sessionManager.currentSession;
    final displayBuses = _buses;
    final displayPassengers = _passengers;

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: ResponsiveContent.wide(
          maxWidth: 1180,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: LinearProgressIndicator(
                      backgroundColor: SmartColors.smartLightBlue,
                      color: SmartColors.electricCyan,
                    ),
                  ),

                // Barra superior Quivox Minimalista
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicBox(
                      isPill: true,
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/role_home');
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'FLEET DISPATCH HUB',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                            color: SmartColors.deepPetrol,
                          ),
                        ),
                        Text(
                          'Panel Transportista',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                      ],
                    ),
                    const UserAppBarActions(),
                  ],
                ),
                const SizedBox(height: 24),

                // Tarjeta Perfil Empresa Neumórfica (con acceso a Sello Trust & Safety)
                NeumorphicBox(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  onTap: () {
                    if (displayBuses.isNotEmpty) {
                      TrustSafetyDialog.show(
                        context,
                        bus: displayBuses.first,
                        isOwnerView: true,
                        onStatusChanged: _loadFleetData,
                      );
                    }
                  },
                  child: Row(
                    children: [
                      NeumorphicBox(
                        isPill: true,
                        isDark: true,
                        padding: const EdgeInsets.all(14),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: SmartColors.electricCyan,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OPERADOR DE FLOTA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: SmartColors.deepPetrol,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session?.name ?? "Transportes Gómez",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: SmartColors.electricCyan,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Flota Certificada SmartRoute (Trust & Safety)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: SmartColors.deepPetrol,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ResponsiveTwoColumns(
                  breakpoint: 880,
                  spacing: 24,
                  left: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Métricas de Negocio Quivox Style (Ocupación y Recaudación)
                      Text(
                        'MÉTRICAS DE OPERACIÓN',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.deepPetrol,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: NeumorphicBox(
                              borderRadius: 20,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'CAPACIDAD',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                          color: SmartColors.deepPetrol,
                                        ),
                                      ),
                                      NeumorphicBox(
                                        isPill: true,
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.event_seat_rounded,
                                          size: 14,
                                          color: SmartColors.electricCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_financialSummary.occupiedSeats}/${_financialSummary.totalSeats}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_financialSummary.occupancyRate.toStringAsFixed(0)}% ocupación activa',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: SmartColors.deepPetrol.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          /* [DESHABILITADO TEMPORALMENTE] Tarjeta de ingresos / pasarela de pago no contemplada aún.
                          const SizedBox(width: 14),
                          Expanded(
                            child: NeumorphicBox(
                              borderRadius: 20,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'INGRESOS',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                          color: SmartColors.deepPetrol,
                                        ),
                                      ),
                                      NeumorphicBox(
                                        isPill: true,
                                        padding: const EdgeInsets.all(6),
                                        child: const Icon(
                                          Icons.payments_rounded,
                                          size: 14,
                                          color: SmartColors.primaryCrimson,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${_financialSummary.totalRevenue.toInt()}',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: SmartColors.deepBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_financialSummary.pendingPaymentsCount} pendiente de cobro',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: SmartColors.deepPetrol.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botones de Acción Quivox Cápsula
                      PrimaryButton(
                        text: 'REGISTRAR NUEVO AUTOBÚS',
                        icon: Icons.add_rounded,
                        isDark: true,
                        onPressed: _navigateToRegisterBus,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        text: 'MONITOREO GPS EN VIVO',
                        icon: Icons.map_rounded,
                        isCyan: true,
                        onPressed: () {
                          TransitLoadingScreen.open(
                            context,
                            targetRoute: '/owner_map',
                            title: 'MAPA DE FLOTA ESCOLAR',
                            subtitle: 'Sincronizando telemetría GPS de tu flota en tiempo real...',
                            badge: 'RADAR DE FLOTA GPS',
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Gestión de Cupos y Pasajeros (Control de cobros/pasarela comentado temporalmente)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'PASAJEROS Y ASIGNACIÓN DE CUPOS',
                              // 'CONTROL DE CUOTAS Y MENSUALIDADES',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                                color: SmartColors.deepPetrol,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NeumorphicBox(
                            isPill: true,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            onTap: _showEnrollStudentDialog,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_add_alt_1_rounded, size: 13, color: SmartColors.deepBlack),
                                const SizedBox(width: 4),
                                Text(
                                  'ASIGNAR CUPO',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      NeumorphicBox(
                        borderRadius: 22,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: displayPassengers.take(6).map((p) {
                            // final isPaid = p.paymentStatus == 'Al día';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: SmartColors.deepBlack,
                                          ),
                                        ),
                                        Text(
                                          'Tutor: ${p.parentName} (${p.busCode})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: SmartColors.deepPetrol.withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  /* [DESHABILITADO TEMPORALMENTE] Chip interactivo de pasarela/estado de pago
                                  NeumorphicBox(
                                    isPill: true,
                                    isDark: isPaid,
                                    isCrimson: !isPaid,
                                    onTap: () => _cyclePaymentStatus(p),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Text(
                                      p.paymentStatus.toUpperCase(),
                                      style: GoogleFonts.jetBrainsMono(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  */
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  right: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lista de Unidades Escolares
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'UNIDADES EN SERVICIO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: SmartColors.deepPetrol,
                            ),
                          ),
                          Text(
                            '${displayBuses.length} ACTIVAS',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: SmartColors.deepPetrol.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayBuses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final bus = displayBuses[index];
                          final coveredSchools = BusService.extractCoveredSchools(
                            _passengers.where((p) => p.busCode == bus.code),
                            fallbackSchool: bus.schoolName,
                          );
                          return _OwnerBusItemImproved(
                            bus: bus,
                            coveredSchools: coveredSchools,
                            onUpdated: _loadFleetData,
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Historial Reciente de Recorridos Quivox
                      Text(
                        'BITÁCORA DE RECORRIDOS',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: SmartColors.deepPetrol,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NeumorphicBox(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(18),
                        child: displayBuses.isEmpty
                            ? Text(
                                'Sin recorridos registrados todavía.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: SmartColors.smartGray,
                                ),
                              )
                            : Column(
                                children: [
                                  for (int i = 0; i < displayBuses.length; i++) ...[
                                    _HistoryRow(
                                      text:
                                          '${displayBuses[i].code} (${displayBuses[i].status}) • ${displayBuses[i].schoolName ?? 'Penonomé'} • Chofer: ${displayBuses[i].driverName}',
                                    ),
                                    if (i < displayBuses.length - 1) const SizedBox(height: 10),
                                  ],
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Cerrar Sesión Carmesí Quivox centrado
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: PrimaryButton(
                      text: 'CERRAR SESIÓN',
                      icon: Icons.logout_rounded,
                      isCrimson: true,
                      onPressed: () {
                        sessionManager.logout();
                        context.go('/login');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OwnerBusItemImproved extends StatefulWidget {
  final BusMock bus;
  final List<String> coveredSchools;
  final VoidCallback? onUpdated;

  const _OwnerBusItemImproved({
    required this.bus,
    this.coveredSchools = const [],
    this.onUpdated,
  });

  @override
  State<_OwnerBusItemImproved> createState() => _OwnerBusItemImprovedState();
}

class _OwnerBusItemImprovedState extends State<_OwnerBusItemImproved> {
  late String currentDriver;

  @override
  void initState() {
    super.initState();
    currentDriver = widget.bus.driverName;
  }

  Future<void> _showAssignDialog() async {
    final authService = context.read<AuthService>();
    final busService = context.read<BusService>();
    final drivers = await authService.getAvailableDrivers();
    if (!mounted) return;

    Map<String, dynamic>? selectedDriver = drivers.isNotEmpty ? drivers.first : null;
    bool createNewMode = drivers.isEmpty;
    bool isSubmitting = false;
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+507 6');

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: SmartColors.neuSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                'ASIGNAR CONDUCTOR',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: SmartColors.deepBlack,
                  letterSpacing: 1.0,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selecciona un conductor registrado o crea uno nuevo para ${widget.bus.code}.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: SmartColors.deepPetrol,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (drivers.isNotEmpty)
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Existente'),
                              selected: !createNewMode,
                              onSelected: (_) => setDialogState(() => createNewMode = false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Nuevo chofer'),
                              selected: createNewMode,
                              onSelected: (_) => setDialogState(() => createNewMode = true),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),
                    if (!createNewMode && drivers.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: selectedDriver?['id']?.toString(),
                        decoration: InputDecoration(
                          labelText: 'Conductor disponible',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: drivers.map((d) {
                          return DropdownMenuItem<String>(
                            value: d['id']?.toString(),
                            child: Text(d['nombre']?.toString() ?? 'Conductor'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setDialogState(() {
                              selectedDriver = drivers.firstWhere((d) => d['id']?.toString() == id);
                            });
                          }
                        },
                      )
                    else ...[
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre completo del conductor',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo (ej: chofer3@smartroute.com)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'CANCELAR',
                    style: GoogleFonts.jetBrainsMono(
                      color: SmartColors.deepPetrol,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartColors.deepBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            Map<String, dynamic>? targetDriver = selectedDriver;
                            if (createNewMode) {
                              targetDriver = await authService.registerDriverProfile(
                                nombre: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                telefono: phoneCtrl.text.trim(),
                              );
                            }
                            if (targetDriver == null) {
                              setDialogState(() => isSubmitting = false);
                              return;
                            }
                            final driverName =
                                targetDriver['nombre']?.toString() ?? 'Conductor Asignado';
                            final driverId = targetDriver['id']?.toString();
                            if (ctx.mounted) Navigator.pop(ctx);
                            await busService.assignDriverToBus(
                              busCode: widget.bus.code,
                              driverName: driverName,
                              driverId: driverId,
                            );
                            if (mounted) {
                              setState(() {
                                currentDriver = driverName;
                              });
                              widget.onUpdated?.call();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error asignando conductor: $e'),
                                  backgroundColor: SmartColors.smartRed,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(
                    isSubmitting ? 'GUARDANDO...' : 'CONFIRMAR',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog() {
    final formKey = GlobalKey<FormState>();
    String editedPlate = widget.bus.plate;
    String editedModel = widget.bus.model;
    String editedCapacity = widget.bus.capacity.toString();
    String editedSchool = widget.bus.schoolName ?? 'Colegio San José';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: SmartColors.neuSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'EDITAR AUTOBÚS',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: SmartColors.deepBlack,
              letterSpacing: 1.0,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Modifica la placa, el modelo o la capacidad de asientos de la unidad ${widget.bus.code}.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: SmartColors.deepPetrol,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: editedPlate,
                    decoration: InputDecoration(
                      labelText: 'Placa vehicular',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: Validators.validatePlate,
                    onChanged: (v) => editedPlate = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: editedModel,
                    decoration: InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => Validators.validateRequired(v, fieldName: 'El modelo'),
                    onChanged: (v) => editedModel = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: editedCapacity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Capacidad de asientos',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: Validators.validateCapacity,
                    onChanged: (v) => editedCapacity = v,
                  ),
                  const SizedBox(height: 12),
                  SchoolSelectorField(
                    label: 'Colegio Asignado',
                    initialValue: editedSchool,
                    onChanged: (v) => editedSchool = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.jetBrainsMono(
                  color: SmartColors.deepPetrol,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartColors.deepBlack,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final busService = context.read<BusService>();
                await busService.updateBus(
                  code: widget.bus.code,
                  plate: editedPlate,
                  model: editedModel,
                  capacity: int.parse(editedCapacity.trim()),
                  schoolName: editedSchool,
                );
                if (mounted) {
                  widget.onUpdated?.call();
                }
              },
              child: Text(
                'GUARDAR',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline =
        widget.bus.status.contains('recorrido') || widget.bus.status == 'Disponible';

    return NeumorphicBox(
      borderRadius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeumorphicBox(
                isPill: true,
                isDark: true,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: SmartColors.electricCyan,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.bus.code,
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        NeumorphicBox(
                          isPill: true,
                          isDark: isOnline,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            widget.bus.status.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isOnline ? SmartColors.electricCyan : SmartColors.deepPetrol,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'PLACA',
                            value: widget.bus.plate,
                          ),
                        ),
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'CONDUCTOR',
                            value: currentDriver,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'CUPOS',
                            value: '${widget.bus.seatsOccupied}/${widget.bus.capacity}',
                          ),
                        ),
                        Expanded(
                          child: _OwnerDetailCol(
                            label: 'COLEGIOS',
                            value: widget.coveredSchools.isEmpty
                                ? 'Múltiples colegios'
                                : widget.coveredSchools.join(' • '),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NeumorphicBox(
                  isPill: true,
                  onTap: _showEditDialog,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'EDITAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: SmartColors.deepBlack,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeumorphicBox(
                  isPill: true,
                  onTap: () {
                    TrustSafetyDialog.show(
                      context,
                      bus: widget.bus,
                      isOwnerView: true,
                      onStatusChanged: widget.onUpdated,
                    );
                  },
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.bus.isVerified ? Icons.verified : Icons.gpp_maybe,
                          size: 13,
                          color: widget.bus.isVerified ? SmartColors.smartGreen : SmartColors.smartYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.bus.isVerified ? 'SELLO OK' : 'AUDITAR',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: widget.bus.isVerified ? SmartColors.smartGreen : SmartColors.smartYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NeumorphicBox(
                  isPill: true,
                  isDark: true,
                  onTap: _showAssignDialog,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'ASIGNAR',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: SmartColors.electricCyan,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerDetailCol extends StatelessWidget {
  final String label;
  final String value;

  const _OwnerDetailCol({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: SmartColors.deepPetrol.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SmartColors.deepBlack,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String text;

  const _HistoryRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: SmartColors.electricCyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: SmartColors.deepBlack,
            ),
          ),
        ),
      ],
    );
  }
}
