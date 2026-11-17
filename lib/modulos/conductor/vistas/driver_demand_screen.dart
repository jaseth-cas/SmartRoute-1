import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:smartroute_flutter/modulos/autenticacion/datos/session_manager.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/empty_state.dart';
import 'package:smartroute_flutter/nucleo/widgets/facial_boarding_dialog.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';
import 'package:smartroute_flutter/nucleo/widgets/responsive_layout.dart';

class DriverDemandScreen extends StatefulWidget {
  const DriverDemandScreen({super.key});

  @override
  State<DriverDemandScreen> createState() => _DriverDemandScreenState();
}

class _DriverDemandScreenState extends State<DriverDemandScreen> {
  String _selectedFilter = 'Todos';
  BusMock? _bus;
  List<StudentPassengerMock> _allPassengers = [];
  bool _isLoading = true;
  StreamSubscription? _attendanceSub;
  StreamSubscription<StudentPassengerMock>? _locationSub;
  RealtimeChannel? _studentsRealtimeChannel;
  StudentService? _studentService;

  @override
  void initState() {
    super.initState();
    _locationSub = StudentService.locationUpdatesStream.listen((updated) {
      if (!mounted) return;
      setState(() {
        final idx = _allPassengers.indexWhere((p) => p.id == updated.id);
        if (idx != -1) {
          _allPassengers[idx] = updated;
        } else if (_bus != null && updated.busCode == _bus!.code) {
          _allPassengers = [..._allPassengers, updated];
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadManifest(silent: false);
      _subscribeToRealtimeAttendance();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    _locationSub?.cancel();
    _studentService?.unsubscribeChannel(_studentsRealtimeChannel);
    super.dispose();
  }

  void _subscribeToRealtimeAttendance() {
    try {
      final attendanceService = context.read<AttendanceService>();
      final studentService = context.read<StudentService>();
      _studentService = studentService;

      _attendanceSub = attendanceService.streamTodayAttendance().listen((_) {
        _loadManifest(silent: true);
      });
      _studentsRealtimeChannel = studentService.subscribeToStudentChanges(
        channelName: 'driver_demand_estudiantes_${DateTime.now().millisecondsSinceEpoch}',
        onChanged: () {
          if (mounted) {
            _loadManifest(silent: true);
          }
        },
      );
    } catch (e) {
      debugPrint('Aviso en suscripción de asistencia: $e');
    }
  }

  Future<void> _loadManifest({bool silent = false}) async {
    if (!silent && _bus == null && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();
      final session = context.read<SessionManager>().currentSession;

      BusMock? bus;
      if (session != null && session.userId.isNotEmpty) {
        bus = await busService.getBusByDriver(session.userId);
      }

      if (bus == null) {
        if (mounted) {
          setState(() {
            _bus = null;
            _allPassengers = [];
            _isLoading = false;
          });
        }
        return;
      }

      final passengers = await studentService.getStudentsByBus(bus.code);

      if (mounted) {
        setState(() {
          _bus = bus;
          _allPassengers = passengers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando manifiesto de conductor: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openFacialScanner([StudentPassengerMock? student]) {
    FacialBoardingDialog.show(
      context,
      targetStudent: student,
      onBoardingCompleted: () => _loadManifest(silent: true),
    );
  }

  Future<void> _manualCheckIn(StudentPassengerMock student) async {
    try {
      final attendanceService = context.read<AttendanceService>();
      await attendanceService.checkInPassenger(
        studentId: student.id,
        method: 'Manual',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abordaje manual registrado para ${student.name}'),
            backgroundColor: SmartColors.deepBlue,
          ),
        );
        _loadManifest(silent: true);
      }
    } catch (e) {
      debugPrint('Error en check-in manual: $e');
    }
  }

  Future<void> _checkOut(StudentPassengerMock student) async {
    try {
      final attendanceService = context.read<AttendanceService>();
      await attendanceService.checkOutPassenger(studentId: student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} entregado en el colegio'),
            backgroundColor: SmartColors.smartGreen,
          ),
        );
        _loadManifest(silent: true);
      }
    } catch (e) {
      debugPrint('Error en check-out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bus = _bus;
    if (bus == null) {
      return Scaffold(
        backgroundColor: SmartColors.neuBackground,
        bottomNavigationBar: DriverBottomBar(
          currentRoute: '/driver_demand',
          onNavigate: (route) => context.go(route),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: SmartColors.deepBlue))
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EmptyState(
                        message: 'Sin autobús asignado',
                        subMessage:
                            'El dueño de flota aún no te ha asignado una unidad escolar.',
                        icon: Icons.directions_bus_outlined,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _loadManifest(silent: false),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('REINTENTAR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SmartColors.deepBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );
    }
    final passengers = _allPassengers;

    final waitingCount = passengers.where((p) => p.status == PassengerStatus.waiting).length;
    final onboardCount = passengers.where((p) => p.status == PassengerStatus.onboard).length;
    final absentCount = passengers.where((p) => p.status == PassengerStatus.absent).length;
    final absentStudents = passengers.where((p) => p.status == PassengerStatus.absent).toList();
    final routeSavings = context.read<AttendanceService>().calculateRouteSavings(passengers);

    final filteredPassengers = passengers.where((p) {
      if (_selectedFilter == 'A bordo') return p.status == PassengerStatus.onboard;
      if (_selectedFilter == 'En espera') return p.status == PassengerStatus.waiting;
      if (_selectedFilter == 'Ausentes') return p.status == PassengerStatus.absent;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/driver_demand',
        onNavigate: (route) => context.go(route),
      ),
      appBar: AppBar(
        title: Text(
          'MANIFIESTO // PASAJEROS ESCOLARES',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: SmartColors.deepBlack,
          ),
        ),
        backgroundColor: SmartColors.neuBackground,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: NeumorphicBox(
              padding: EdgeInsets.zero,
              isPill: true,
              child: IconButton(
                tooltip: 'Terminal Facial AI',
                icon: const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: SmartColors.deepBlue,
                  size: 20,
                ),
                onPressed: () => _openFacialScanner(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SmartColors.deepBlue))
          : ResponsiveContent(
              maxWidth: 1000,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Superior Neumórfico
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: NeumorphicBox(
                      padding: const EdgeInsets.all(18),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  bus.routeName ?? 'Ruta Escolar Norte',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: SmartColors.deepBlack,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: SmartColors.deepBlack,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${bus.seatsOccupied}/${bus.capacity} CUPOS',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: SmartColors.vibrantCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Contadores Quivox
                          Row(
                            children: [
                              _MiniCounter(
                                label: 'A BORDO',
                                count: onboardCount,
                                color: SmartColors.deepBlack,
                                accentColor: SmartColors.vibrantCyan,
                              ),
                              const SizedBox(width: 8),
                              _MiniCounter(
                                label: 'EN ESPERA',
                                count: waitingCount,
                                color: SmartColors.deepBlue,
                                accentColor: SmartColors.deepBlue,
                              ),
                              const SizedBox(width: 8),
                              _MiniCounter(
                                label: 'AUSENTES',
                                count: absentCount,
                                color: SmartColors.primaryCrimson,
                                accentColor: SmartColors.primaryCrimson,
                              ),
                            ],
                          ),
                          if (absentCount > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SmartColors.primaryCrimson.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_run_rounded, color: SmartColors.primaryCrimson, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${absentStudents.map((s) => s.name).join(', ')} reportó inasistencia (Ahorro: ${routeSavings['savedMinutes']} min / ${routeSavings['savedKilometers']} km).',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: SmartColors.primaryCrimson,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Botón Escáner Facial
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: PrimaryButton(
                      text: 'TERMINAL BIOMÉTRICA FACIAL AI',
                      icon: Icons.camera_alt_rounded,
                      height: 48,
                      onPressed: () => _openFacialScanner(),
                    ),
                  ),

                  // Filtros tipo Quivox Segmented Pills
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Todos', 'En espera', 'A bordo', 'Ausentes'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedFilter = filter),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? SmartColors.deepBlack : SmartColors.ghostWhite,
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
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : SmartColors.neuBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  filter.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: isSelected ? SmartColors.ghostWhite : SmartColors.smartGray,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Lista o Grilla Responsiva de Estudiantes
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth >= 720;
                        if (isWide) {
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.1,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filteredPassengers.length,
                            itemBuilder: (context, index) {
                              final student = filteredPassengers[index];
                              return _StudentManifestCard(
                                student: student,
                                onScanFacial: () => _openFacialScanner(student),
                                onManualCheckIn: () => _manualCheckIn(student),
                                onCheckOut: () => _checkOut(student),
                              );
                            },
                          );
                        } else {
                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
                            itemCount: filteredPassengers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = filteredPassengers[index];
                              return _StudentManifestCard(
                                student: student,
                                onScanFacial: () => _openFacialScanner(student),
                                onManualCheckIn: () => _manualCheckIn(student),
                                onCheckOut: () => _checkOut(student),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MiniCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color accentColor;

  const _MiniCounter({
    required this.label,
    required this.count,
    required this.color,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: SmartColors.neuInset,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count'.padLeft(2, '0'),
              style: GoogleFonts.jetBrainsMono(
                fontWeight: FontWeight.w900,
                color: accentColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: SmartColors.smartGray,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentManifestCard extends StatelessWidget {
  final StudentPassengerMock student;
  final VoidCallback onScanFacial;
  final VoidCallback onManualCheckIn;
  final VoidCallback onCheckOut;

  const _StudentManifestCard({
    required this.student,
    required this.onScanFacial,
    required this.onManualCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsent = student.status == PassengerStatus.absent;
    final isOnboard = student.status == PassengerStatus.onboard;
    final isDelivered = student.status == PassengerStatus.delivered;

    String badgeText;
    Color badgeColor;

    switch (student.status) {
      case PassengerStatus.onboard:
        badgeText = 'A BORDO (${student.lastBoardingTime ?? ""})';
        badgeColor = SmartColors.vibrantCyan;
        break;
      case PassengerStatus.waiting:
        badgeText = 'EN ESPERA';
        badgeColor = SmartColors.deepBlue;
        break;
      case PassengerStatus.absent:
        badgeText = 'AUSENCIA';
        badgeColor = SmartColors.primaryCrimson;
        break;
      case PassengerStatus.delivered:
        badgeText = 'ENTREGADO';
        badgeColor = Colors.purple;
        break;
    }

    return NeumorphicBox(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(22),
      isInset: isAbsent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAbsent ? SmartColors.neuInset : SmartColors.deepBlack,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '#${student.order}',
                    style: GoogleFonts.jetBrainsMono(
                      fontWeight: FontWeight.w800,
                      color: isAbsent ? SmartColors.smartGray : SmartColors.vibrantCyan,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isAbsent ? SmartColors.smartGray : SmartColors.deepBlack,
                        decoration: isAbsent ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.pickupAddress,
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: SmartColors.smartGray),
                    ),
                    Text(
                      'Tutor: ${student.parentName} (${student.parentPhone})',
                      style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: SmartColors.deepBlue),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.jetBrainsMono(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          if (!isAbsent) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (!isOnboard && !isDelivered) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: onScanFacial,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlack,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: SmartColors.deepBlack.withValues(alpha: 0.25),
                              offset: const Offset(0, 3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.face_retouching_natural_rounded, color: SmartColors.vibrantCyan, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'CHECK-IN FACIAL AI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: SmartColors.ghostWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Check-in Manual (RF-10)',
                    icon: const Icon(Icons.touch_app, color: SmartColors.deepBlue),
                    style: IconButton.styleFrom(
                      backgroundColor: SmartColors.neuInset,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onManualCheckIn,
                  ),
                ],
                if (isOnboard)
                  Expanded(
                    child: GestureDetector(
                      onTap: onCheckOut,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: SmartColors.deepBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: SmartColors.vibrantCyan, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'MARCAR ENTREGADO EN COLEGIO',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: SmartColors.ghostWhite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isDelivered)
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: SmartColors.neuInset,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '✓ ESTUDIANTE ENTREGADO EN COLEGIO',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.deepBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
