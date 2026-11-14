import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Modelo ligero para la tarjeta interactiva de Card Sorting
class StudentStopCardItem {
  final int id;
  final String name;
  final String pickupAddress;
  final String schoolName;
  final String grade;
  final LatLng position;
  final double distanceMeters;
  final String estimatedTime;
  final String? photoAsset;
  final bool isAbsent;

  StudentStopCardItem({
    required this.id,
    required this.name,
    required this.pickupAddress,
    required this.schoolName,
    required this.grade,
    required this.position,
    required this.distanceMeters,
    required this.estimatedTime,
    this.photoAsset,
    this.isAbsent = false,
  });

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(2)} km';
    }
  }
}

/// Pantalla 2 del nuevo flujo del conductor:
/// Ventana de Card Sorting para estudiantes con presencia confirmada hoy y su distancia actual.
/// Permite al conductor reordenar las paradas y confirmar la generación de ruta con Dijkstra.
class DriverCardSortingScreen extends StatefulWidget {
  const DriverCardSortingScreen({super.key});

  @override
  State<DriverCardSortingScreen> createState() => _DriverCardSortingScreenState();
}

class _DriverCardSortingScreenState extends State<DriverCardSortingScreen> {
  // Lista de estudiantes que asisten hoy para reordenar
  late List<StudentStopCardItem> _attendingStudents;
  // Estudiantes ausentes (omitidos automáticamente)
  late List<StudentStopCardItem> _absentStudents;

  @override
  void initState() {
    super.initState();
    _initializeStudentCards();
  }

  void _initializeStudentCards() {
    // Alumnos que asisten hoy en Penonomé
    _attendingStudents = [
      StudentStopCardItem(
        id: 1,
        name: 'Mateo Gómez',
        pickupAddress: 'Casa (Vía hacia Sonadora, Penonomé)',
        schoolName: 'Colegio San José',
        grade: '4° Primaria • Salón A',
        position: const LatLng(8.5281, -80.3565),
        distanceMeters: 620,
        estimatedTime: '07:05 AM',
        photoAsset: null,
      ),
      StudentStopCardItem(
        id: 2,
        name: 'Sofía Martínez',
        pickupAddress: 'Casa (Conjunto El Roble, Calle 4)',
        schoolName: 'Colegio San José',
        grade: '5° Primaria • Salón B',
        position: const LatLng(8.5242, -80.3522),
        distanceMeters: 940,
        estimatedTime: '07:12 AM',
        photoAsset: null,
      ),
      StudentStopCardItem(
        id: 3,
        name: 'Lucas Rodríguez',
        pickupAddress: 'Casa (Av. 19 # 104-50, Penonomé)',
        schoolName: 'Colegio San José',
        grade: '3° Primaria • Salón C',
        position: const LatLng(8.5215, -80.3532),
        distanceMeters: 1420,
        estimatedTime: '07:18 AM',
        photoAsset: null,
      ),
      StudentStopCardItem(
        id: 5,
        name: 'Eliam Fernández',
        pickupAddress: 'Casa (Vía Cristo Rey, Penonomé)',
        schoolName: 'Colegio San José',
        grade: '6° Primaria • Salón A',
        position: const LatLng(8.5186, -80.3541),
        distanceMeters: 1880,
        estimatedTime: '07:24 AM',
        photoAsset: 'assets/images/eliam_student.png',
      ),
    ];

    // Alumnos que notificaron ausencia
    _absentStudents = [
      StudentStopCardItem(
        id: 4,
        name: 'Valentina Castro',
        pickupAddress: 'Calle 72 # 9-15 (Torres del Parque)',
        schoolName: 'Colegio San José',
        grade: '4° Primaria',
        position: const LatLng(8.5170, -80.3545),
        distanceMeters: 2150,
        estimatedTime: 'Omitida',
        isAbsent: true,
      ),
    ];
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _attendingStudents.removeAt(oldIndex);
      _attendingStudents.insert(newIndex, item);
    });
  }

  void _autoSortByDistance() {
    setState(() {
      _attendingStudents.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paradas auto-ordenadas por proximidad a tu posición',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: SmartColors.deepBlue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmAndGenerateRoute() {
    // Pasa la lista ordenada de estudiantes a la pantalla del mapa y cálculo con Dijkstra
    context.push(
      '/driver_dijkstra_routing',
      extra: _attendingStudents,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: SmartColors.deepBlack, size: 20),
          onPressed: () => context.go('/driver_welcome_splash'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ORGANIZAR SECUENCIA DE RUTA',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: SmartColors.deepBlue,
              ),
            ),
            Text(
              'Card Sorting de Estudiantes de Hoy',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: SmartColors.deepBlack,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: _autoSortByDistance,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: SmartColors.vibrantCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SmartColors.vibrantCyan.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me_rounded, color: SmartColors.deepBlue, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'POR CERCANÍA',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: SmartColors.deepBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera Informativa con Guía de Interacción
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: SmartColors.neuSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: SmartColors.neuBorder),
                      boxShadow: [
                        BoxShadow(
                          color: SmartColors.neuDarkShadow,
                          offset: const Offset(2, 3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: SmartColors.vibrantCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: SmartColors.deepBlue,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mantén presionado y arrastra para reordenar',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: SmartColors.deepBlack,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Personaliza el orden de recogida según el tráfico actual antes de calcular la ruta mínima con Dijkstra.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: SmartColors.smartGray,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Lista Reordenable (Card Sorting)
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemCount: _attendingStudents.length + (_absentStudents.isNotEmpty ? 1 : 0),
                      onReorder: (oldIndex, newIndex) {
                        // Impedir mover la sección de ausentes
                        if (oldIndex >= _attendingStudents.length || newIndex > _attendingStudents.length) {
                          return;
                        }
                        _onReorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        // Sección de ausencias al final
                        if (index == _attendingStudents.length) {
                          return _buildAbsentSection(key: const ValueKey('absent_section'));
                        }

                        final student = _attendingStudents[index];
                        final stopNumber = index + 1;

                        return _buildDraggableStudentCard(
                          key: ValueKey(student.id),
                          student: student,
                          stopNumber: stopNumber,
                          index: index,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: SmartColors.neuSurface,
          border: Border(top: BorderSide(color: SmartColors.neuBorder.withValues(alpha: 0.8))),
          boxShadow: [
            BoxShadow(
              color: SmartColors.deepBlack.withValues(alpha: 0.05),
              offset: const Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  // Resumen de Paradas
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SmartColors.smartGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_attendingStudents.length} PARADAS ACTIVAS',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Destino: Colegio San José (07:30 AM)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: SmartColors.smartGray,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Botón Principal: Confirmar y Generar Ruta
                  Flexible(
                    child: ElevatedButton(
                      onPressed: _confirmAndGenerateRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SmartColors.deepBlack,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width < 600 ? 14 : 22,
                          vertical: MediaQuery.sizeOf(context).width < 600 ? 12 : 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: SmartColors.vibrantCyan, width: 1.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.alt_route_rounded, color: SmartColors.vibrantCyan, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Confirmar y Generar Ruta',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: MediaQuery.sizeOf(context).width < 600 ? 12 : 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableStudentCard({
    required Key key,
    required StudentStopCardItem student,
    required int stopNumber,
    required int index,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: NeumorphicBox(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(22),
        child: Row(
          children: [
            // Indicador de Número de Parada
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: index == 0 ? SmartColors.vibrantCyan : SmartColors.neuInset,
                shape: BoxShape.circle,
                border: Border.all(
                  color: index == 0 ? SmartColors.deepBlue : SmartColors.neuBorder,
                  width: 1.4,
                ),
              ),
              child: Center(
                child: Text(
                  stopNumber.toString().padLeft(2, '0'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: index == 0 ? SmartColors.deepBlack : SmartColors.deepBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Foto / Avatar del Alumno
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                color: SmartColors.neuInset,
                child: student.photoAsset != null
                    ? Image.asset(
                        student.photoAsset!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(student.name),
                      )
                    : _buildAvatarFallback(student.name),
              ),
            ),

            const SizedBox(width: 12),

            // Información del Alumno y su Posición
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          student.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SmartColors.smartGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'CONFIRMADO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.smartGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.grade,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: SmartColors.smartGray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Fila de Ubicación y Distancia
                  Row(
                    children: [
                      const Icon(Icons.home_rounded, size: 12, color: SmartColors.deepBlue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          student.pickupAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: SmartColors.deepBlack.withValues(alpha: 0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Píldora de distancia y tiempo estimado (adaptativa en teléfono)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: SmartColors.neuInset,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.navigation_rounded, size: 10, color: SmartColors.vibrantCyan),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'A ${student.formattedDistance} de ti',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: SmartColors.deepBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: SmartColors.neuInset,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 10, color: SmartColors.smartGray),
                            const SizedBox(width: 4),
                            Text(
                              student.estimatedTime,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: SmartColors.smartGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icono de Agarrador (Drag Handle)
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SmartColors.neuInset,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: SmartColors.smartGray,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentSection({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.event_busy_rounded, color: SmartColors.primaryCrimson, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'INASISTENCIAS NOTIFICADAS (OMITIDAS AUTOMÁTICAMENTE)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: SmartColors.primaryCrimson,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._absentStudents.map((absent) {
          return Opacity(
            opacity: 0.65,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SmartColors.primaryCrimson.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: SmartColors.primaryCrimson.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: SmartColors.primaryCrimson.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.close_rounded, color: SmartColors.primaryCrimson, size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          absent.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        Text(
                          '${absent.pickupAddress} • Parada excluida (-10 min)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: SmartColors.primaryCrimson,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join();
    return Container(
      color: SmartColors.deepBlue.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: SmartColors.deepBlue,
          ),
        ),
      ),
    );
  }
}

