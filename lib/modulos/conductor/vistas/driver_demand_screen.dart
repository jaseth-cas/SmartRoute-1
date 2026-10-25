import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/bus_service.dart';
import 'package:smartroute_flutter/nucleo/servicios/student_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/driver_bottom_bar.dart';
import 'package:smartroute_flutter/nucleo/widgets/facial_boarding_dialog.dart';
import 'package:smartroute_flutter/nucleo/widgets/smart_route_card.dart';

/// Pantalla de Manifiesto de Pasajeros y Control de Abordaje Escolar (Driver).
/// Reemplaza el mapa de demanda universitario tradicional por la gestión operativa de
/// recogida de estudiantes, ausencias reportadas por padres y biometría facial.
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadManifest();
      _subscribeToRealtimeAttendance();
    });
  }

  @override
  void dispose() {
    _attendanceSub?.cancel();
    super.dispose();
  }

  void _subscribeToRealtimeAttendance() {
    try {
      final attendanceService = context.read<AttendanceService>();
      _attendanceSub = attendanceService.streamTodayAttendance().listen((_) {
        _loadManifest(silent: true);
      });
    } catch (e) {
      debugPrint('Aviso en suscripción de asistencia: $e');
    }
  }

  Future<void> _loadManifest({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final busService = context.read<BusService>();
      final studentService = context.read<StudentService>();

      final bus = await busService.getBusByCode('BUS-01') ?? (await busService.getAllBuses()).first;
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
      if (mounted && !silent) {
        setState(() => _isLoading = false);
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
            backgroundColor: SmartColors.smartBlue,
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
    final waitingCount = _allPassengers.where((p) => p.status == PassengerStatus.waiting).length;
    final onboardCount = _allPassengers.where((p) => p.status == PassengerStatus.onboard).length;
    final absentCount = _allPassengers.where((p) => p.status == PassengerStatus.absent).length;
    final absentStudents = _allPassengers.where((p) => p.status == PassengerStatus.absent).toList();

    final filteredPassengers = _allPassengers.where((p) {
      if (_selectedFilter == 'A bordo') return p.status == PassengerStatus.onboard;
      if (_selectedFilter == 'En espera') return p.status == PassengerStatus.waiting;
      if (_selectedFilter == 'Ausentes') return p.status == PassengerStatus.absent;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: SmartColors.smartBackground,
      bottomNavigationBar: DriverBottomBar(
        currentRoute: '/driver_demand',
        onNavigate: (route) => context.go(route),
      ),
      appBar: AppBar(
        title: const Text(
          'Manifiesto de Pasajeros',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: SmartColors.smartBlue),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Recargar manifiesto',
            icon: const Icon(Icons.refresh, color: SmartColors.smartBlue),
            onPressed: () => _loadManifest(),
          ),
          IconButton(
            tooltip: 'Terminal Facial AI',
            icon: const Icon(Icons.face_retouching_natural, color: SmartColors.smartBlue),
            onPressed: () => _openFacialScanner(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: SmartColors.smartBlue))
          : RefreshIndicator(
              onRefresh: () => _loadManifest(),
              color: SmartColors.smartBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner de Ruta y Capacidad del Bus
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _bus?.routeName ?? 'Ruta Escolar Norte',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: SmartColors.smartText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartColors.smartLightBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_allPassengers.length}/${_bus?.capacity ?? 16} Cupos',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: SmartColors.smartBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Resumen rápido de contadores
                        Row(
                          children: [
                            _MiniCounter(
                              label: 'A bordo',
                              count: onboardCount,
                              color: SmartColors.smartGreen,
                              bgColor: SmartColors.smartLightGreen,
                            ),
                            const SizedBox(width: 8),
                            _MiniCounter(
                              label: 'En espera',
                              count: waitingCount,
                              color: SmartColors.smartBlue,
                              bgColor: SmartColors.smartLightBlue,
                            ),
                            const SizedBox(width: 8),
                            _MiniCounter(
                              label: 'Ausentes',
                              count: absentCount,
                              color: SmartColors.smartRed,
                              bgColor: SmartColors.smartLightRed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Aviso Dinámico de Ausencias Reportadas (Recálculo Inteligente de Ruta - RF-11)
                  if (absentCount > 0)
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Ámbar suave
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_run, color: Color(0xFFD97706), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${absentStudents.map((s) => '${s.name} (Parada #${s.order})').join(', ')} reportó inasistencia. La parada ha sido omitida para ahorrar combustible.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botón de Terminal Facial
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartColors.smartBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _openFacialScanner(),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Abrir Terminal de Abordaje Facial AI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Filtros
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Todos', 'En espera', 'A bordo', 'Ausentes'].map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              selectedColor: SmartColors.smartLightBlue,
                              labelStyle: TextStyle(color: isSelected ? SmartColors.smartBlue : SmartColors.smartGray),
                              onSelected: (val) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Lista de Estudiantes en orden de recogida
                  Expanded(
                    child: filteredPassengers.isEmpty
                        ? const Center(
                            child: Text('No hay pasajeros en esta categoría', style: TextStyle(color: SmartColors.smartGray)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16.0),
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
  final Color bgColor;

  const _MiniCounter({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
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

    Color badgeColor;
    Color badgeBg;
    String badgeText;

    switch (student.status) {
      case PassengerStatus.onboard:
        badgeColor = SmartColors.smartGreen;
        badgeBg = SmartColors.smartLightGreen;
        badgeText = 'A bordo • ${student.lastBoardingTime ?? ""}';
        break;
      case PassengerStatus.waiting:
        badgeColor = SmartColors.smartBlue;
        badgeBg = SmartColors.smartLightBlue;
        badgeText = 'En espera de recogida';
        break;
      case PassengerStatus.absent:
        badgeColor = SmartColors.smartRed;
        badgeBg = SmartColors.smartLightRed;
        badgeText = 'Ausente hoy';
        break;
      case PassengerStatus.delivered:
        badgeColor = Colors.purple;
        badgeBg = Colors.purple.shade50;
        badgeText = 'Entregado en colegio';
        break;
    }

    return SmartRouteCard(
      color: isAbsent ? Colors.grey.shade100 : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número de parada / Orden
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isAbsent ? Colors.grey.shade300 : SmartColors.smartLightBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#${student.order}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isAbsent ? Colors.grey.shade600 : SmartColors.smartBlue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Datos del alumno
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isAbsent ? Colors.grey.shade600 : SmartColors.smartText,
                        decoration: isAbsent ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      student.pickupAddress,
                      style: const TextStyle(fontSize: 12, color: SmartColors.smartGray),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tutor: ${student.parentName} (${student.parentPhone})',
                      style: const TextStyle(fontSize: 11, color: SmartColors.smartGray),
                    ),
                  ],
                ),
              ),
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Botones de acción según el estado
          if (!isAbsent)
            Row(
              children: [
                if (!isOnboard && !isDelivered) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SmartColors.smartBlue,
                        side: const BorderSide(color: SmartColors.smartBlue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onScanFacial,
                      icon: const Icon(Icons.face, size: 16),
                      label: const Text('Check-in Facial AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Check-in Manual (RF-10)',
                    icon: const Icon(Icons.touch_app, color: SmartColors.smartBlue),
                    style: IconButton.styleFrom(
                      backgroundColor: SmartColors.smartLightBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onManualCheckIn,
                  ),
                ],
                if (isOnboard)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartColors.smartGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onCheckOut,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Marcar Entregado en Colegio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isDelivered)
                  const Expanded(
                    child: Text(
                      '✓ Estudiante en el colegio seguro',
                      style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
