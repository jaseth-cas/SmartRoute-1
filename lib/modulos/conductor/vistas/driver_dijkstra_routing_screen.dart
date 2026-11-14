import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:smartroute_flutter/modulos/conductor/vistas/driver_card_sorting_screen.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';

/// Pantalla 3 del nuevo flujo del conductor:
/// Ventana completa del mapa con simulación animada del cálculo de camino mínimo con Dijkstra
/// por alumno, consolidación de la ruta óptima final y regreso al panel principal del conductor.
class DriverDijkstraRoutingScreen extends StatefulWidget {
  final List<StudentStopCardItem>? orderedStudents;

  const DriverDijkstraRoutingScreen({
    super.key,
    this.orderedStudents,
  });

  @override
  State<DriverDijkstraRoutingScreen> createState() => _DriverDijkstraRoutingScreenState();
}

class _DriverDijkstraRoutingScreenState extends State<DriverDijkstraRoutingScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  // Lista ordenada de estudiantes proveniente del Card Sorting
  late List<StudentStopCardItem> _students;

  // Coordenadas clave en Penonomé
  final LatLng _busOrigin = const LatLng(8.5270, -80.3512);
  final LatLng _schoolDest = const LatLng(8.5154, -80.3482);

  // Fases de la animación de Dijkstra (0 = Inicio, 1 = Alumno 1, 2 = Alumno 2, 3 = Alumno 3, 4 = Alumno 4, 5 = Final)
  int _currentStep = 0;
  String _algorithmStatusText = 'Inicializando Grafo G(V, E) en Penonomé...';
  String _dijkstraFormulaText = 'd(v) = min(d(v), d(u) + w(u,v))';
  double _calculationProgress = 0.0;
  bool _isRouteOptimized = false;

  // Segmentos de ruta calculados y fijados por Dijkstra
  final List<List<LatLng>> _confirmedSegments = [];
  // Segmentos explorados/candidatos que parpadean durante el escaneo
  List<LatLng> _currentScanningSegment = [];

  Timer? _stepTimer;
  Timer? _autoFinishTimer;

  // Nodos de grafo completo
  late List<LatLng> _graphNodes;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Si no se pasaron estudiantes por extra, usar valores por defecto
    _students = widget.orderedStudents ?? [
      StudentStopCardItem(
        id: 1,
        name: 'Mateo Gómez',
        pickupAddress: 'Vía hacia Sonadora',
        schoolName: 'Colegio San José',
        grade: '4° Primaria',
        position: const LatLng(8.5281, -80.3565),
        distanceMeters: 620,
        estimatedTime: '07:05 AM',
      ),
      StudentStopCardItem(
        id: 2,
        name: 'Sofía Martínez',
        pickupAddress: 'Conjunto El Roble',
        schoolName: 'Colegio San José',
        grade: '5° Primaria',
        position: const LatLng(8.5242, -80.3522),
        distanceMeters: 940,
        estimatedTime: '07:12 AM',
      ),
      StudentStopCardItem(
        id: 3,
        name: 'Lucas Rodríguez',
        pickupAddress: 'Av. 19 # 104-50',
        schoolName: 'Colegio San José',
        grade: '3° Primaria',
        position: const LatLng(8.5215, -80.3532),
        distanceMeters: 1420,
        estimatedTime: '07:18 AM',
      ),
      StudentStopCardItem(
        id: 5,
        name: 'Eliam Fernández',
        pickupAddress: 'Vía Cristo Rey',
        schoolName: 'Colegio San José',
        grade: '6° Primaria',
        position: const LatLng(8.5186, -80.3541),
        distanceMeters: 1880,
        estimatedTime: '07:24 AM',
      ),
    ];

    _graphNodes = [
      _busOrigin,
      ..._students.map((s) => s.position),
      const LatLng(8.5172, -80.3540), // Giro barriada escolar
      const LatLng(8.5160, -80.3522), // Calle conexión
      _schoolDest,
    ];

    // Iniciar simulación por pasos del algoritmo de Dijkstra
    _startDijkstraSimulation();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _autoFinishTimer?.cancel();
    super.dispose();
  }

  void _startDijkstraSimulation() {
    int step = 0;
    const totalSteps = 6;

    _stepTimer = Timer.periodic(const Duration(milliseconds: 1300), (timer) {
      step++;
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentStep = step;
        _calculationProgress = (step / totalSteps).clamp(0.0, 1.0);

        if (step == 1) {
          // Fase 1: Dijkstra para Alumno 1
          final student = _students[0];
          _algorithmStatusText = 'Dijkstra: Explorando camino mínimo hacia ${student.name}...';
          _dijkstraFormulaText = 'Nodo Origen TBX-492 -> Parada 01: Evaluando 3 aristas adyacentes';
          _currentScanningSegment = [_busOrigin, const LatLng(8.5278, -80.3530), student.position];
          _confirmedSegments.add([
            _busOrigin,
            const LatLng(8.5276, -80.3535),
            student.position,
          ]);
        } else if (step == 2) {
          // Fase 2: Dijkstra para Alumno 2
          final student = _students[1];
          _algorithmStatusText = 'Dijkstra: Relajando aristas hacia ${student.name}...';
          _dijkstraFormulaText = 'dist[Parada 02] = dist[Parada 01] + w(e): Arista mínima elegida (540m)';
          _currentScanningSegment = [_students[0].position, const LatLng(8.5260, -80.3540), student.position];
          _confirmedSegments.add([
            _students[0].position,
            const LatLng(8.5255, -80.3538),
            student.position,
          ]);
        } else if (step == 3) {
          // Fase 3: Dijkstra para Alumno 3
          final student = _students[2];
          _algorithmStatusText = 'Dijkstra: Optimizando tramo para ${student.name}...';
          _dijkstraFormulaText = 'Evaluando semáforos y flujo: Vía Sonadora Sur seleccionada';
          _currentScanningSegment = [_students[1].position, student.position];
          _confirmedSegments.add([
            _students[1].position,
            const LatLng(8.5228, -80.3528),
            student.position,
          ]);
        } else if (step == 4) {
          // Fase 4: Dijkstra para Alumno 4
          final student = _students[3];
          _algorithmStatusText = 'Dijkstra: Calculando camino mínimo para ${student.name}...';
          _dijkstraFormulaText = 'Min-Heap: Extracción nodo de menor costo -> ${student.name} confirmado';
          _currentScanningSegment = [_students[2].position, student.position];
          _confirmedSegments.add([
            _students[2].position,
            const LatLng(8.5200, -80.3536),
            student.position,
          ]);
        } else if (step == 5) {
          // Fase 5: Conexión con Destino Colegio San José
          _algorithmStatusText = 'Dijkstra: Enlazando con Destino Final Colegio San José...';
          _dijkstraFormulaText = 'Tramo de acceso escolar: Vía Simón Bolívar -> Colegio San José';
          _currentScanningSegment = [_students.last.position, const LatLng(8.5160, -80.3522), _schoolDest];
          _confirmedSegments.add([
            _students.last.position,
            const LatLng(8.5172, -80.3540),
            const LatLng(8.5160, -80.3522),
            const LatLng(8.5156, -80.3500),
            _schoolDest,
          ]);
        } else if (step >= 6) {
          // Fase 6: Consolidación Final de la Ruta Óptima
          timer.cancel();
          _isRouteOptimized = true;
          _calculationProgress = 1.0;
          _currentScanningSegment = [];
          _algorithmStatusText = '¡Ruta Óptima Calculada Exitosamente!';
          _dijkstraFormulaText = 'Costo Mínimo Global: 4.8 km • 14 min • 0 alertas de congestión';

          // Auto-transición al panel principal del conductor en 3.5 segundos
          _autoFinishTimer = Timer(const Duration(milliseconds: 3600), () {
            _goToDriverHomeScreen();
          });
        }
      });
    });
  }

  void _goToDriverHomeScreen() {
    _stepTimer?.cancel();
    _autoFinishTimer?.cancel();
    if (mounted) {
      context.go('/driver_home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Polilínea acumulada consolidada
    final consolidatedPoints = <LatLng>[];
    for (final seg in _confirmedSegments) {
      consolidatedPoints.addAll(seg);
    }

    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: Stack(
        children: [
          // 1. Mapa Interactivo Completo
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(8.5218, -80.3525),
              initialZoom: 15.0,
              minZoom: 12.0,
              maxZoom: 18.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartroute.smartroute_flutter',
              ),

              // Capa de Polilíneas de Dijkstra
              PolylineLayer(
                polylines: [
                  // 1. Segmentos de escaneo/exploración Dijkstra (Amarillo/Ámbar parpadeante)
                  if (_currentScanningSegment.isNotEmpty)
                    Polyline(
                      points: _currentScanningSegment,
                      color: SmartColors.smartYellow.withValues(alpha: 0.65),
                      strokeWidth: 8.0,
                    ),

                  // 2. Halo resplandeciente de ruta consolidada
                  if (consolidatedPoints.isNotEmpty)
                    Polyline(
                      points: consolidatedPoints,
                      color: _isRouteOptimized
                          ? SmartColors.vibrantCyan.withValues(alpha: 0.45)
                          : SmartColors.deepBlue.withValues(alpha: 0.35),
                      strokeWidth: 10.0,
                    ),

                  // 3. Línea central de camino mínimo confirmado
                  if (consolidatedPoints.isNotEmpty)
                    Polyline(
                      points: consolidatedPoints,
                      color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                      strokeWidth: 5.5,
                    ),
                ],
              ),

              // Marcadores del Grafo
              MarkerLayer(
                markers: [
                  // Origen: Bus del Conductor
                  Marker(
                    point: _busOrigin,
                    width: 140,
                    height: 52,
                    child: _buildNodeMarker(
                      title: 'INICIO TBX-492',
                      subtitle: 'Posición actual',
                      icon: Icons.directions_bus_filled_rounded,
                      color: SmartColors.deepBlue,
                    ),
                  ),

                  // Nodos de los Estudiantes del Card Sorting
                  ..._students.asMap().entries.map((entry) {
                    final index = entry.key;
                    final student = entry.value;
                    final isConfirmed = _currentStep > index;

                    return Marker(
                      point: student.position,
                      width: 150,
                      height: 54,
                      child: _buildNodeMarker(
                        title: '0${index + 1}. ${student.name.split(' ').first}',
                        subtitle: student.formattedDistance,
                        icon: Icons.person_pin_circle_rounded,
                        color: isConfirmed ? SmartColors.vibrantCyan : SmartColors.smartGray,
                        isHighlighted: _currentStep == index + 1,
                      ),
                    );
                  }),

                  // Destino: Colegio San José
                  Marker(
                    point: _schoolDest,
                    width: 140,
                    height: 52,
                    child: _buildNodeMarker(
                      title: 'COL. SAN JOSÉ',
                      subtitle: 'Destino Final',
                      icon: Icons.school_rounded,
                      color: SmartColors.smartGreen,
                      isHighlighted: _isRouteOptimized,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. HUD Superior de Dijkstra: Monitor Algorítmico y Telemetría
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: SmartColors.deepBlack.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: SmartColors.deepBlack.withValues(alpha: 0.4),
                        offset: const Offset(0, 6),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Fila Superior: Badge Algoritmo y Botón Omitir
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: _isRouteOptimized
                                      ? SmartColors.vibrantCyan.withValues(alpha: 0.2)
                                      : SmartColors.smartYellow.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isRouteOptimized ? 'DIJKSTRA // ÓPTIMO ALCANZADO' : 'DIJKSTRA // CALCULANDO RUTA MÍNIMA',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                        color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Botón Omitir e ir directamente al mapa principal
                          GestureDetector(
                            onTap: _goToDriverHomeScreen,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: SmartColors.neuInset.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'OMITIR E IR AL MAPA',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.skip_next_rounded, size: 14, color: Colors.white70),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Título de la Fase y Fórmula
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _algorithmStatusText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _dijkstraFormulaText,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: SmartColors.vibrantCyan,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: SmartColors.neuInset.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(_calculationProgress * 100).toInt()}%',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _isRouteOptimized ? SmartColors.vibrantCyan : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Barra de Progreso del Algoritmo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _calculationProgress,
                          minHeight: 5,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.smartYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Tarjeta Inferior de Consolidación y Transición
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: NeumorphicBox(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  borderRadius: BorderRadius.circular(24),
                  child: Row(
                    children: [
                      // Icono de Estado
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _isRouteOptimized
                              ? SmartColors.smartGreen.withValues(alpha: 0.15)
                              : SmartColors.deepBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _isRouteOptimized ? Icons.check_circle_rounded : Icons.hub_rounded,
                            color: _isRouteOptimized ? SmartColors.smartGreen : SmartColors.deepBlue,
                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Detalles de Ruta Mínima Consolidada
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRouteOptimized ? 'RUTA ESCOLAR LISTA PARA NAVEGACIÓN' : 'CONSTRUYENDO GRAFO DE RECOGIDA',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: _isRouteOptimized ? SmartColors.smartGreen : SmartColors.smartGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isRouteOptimized
                                  ? '4.8 km • 14 min • 4 estudiantes en secuencia óptima'
                                  : 'Evaluando distancias euclidianas y pesos viales...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: SmartColors.deepBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Botón para ingresar al panel principal
                      ElevatedButton(
                        onPressed: _goToDriverHomeScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SmartColors.deepBlack,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _isRouteOptimized ? SmartColors.vibrantCyan : SmartColors.neuBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isRouteOptimized ? 'Iniciar Navegación' : 'Ir al Panel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, color: SmartColors.vibrantCyan, size: 18),
                          ],
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
    );
  }

  Widget _buildNodeMarker({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SmartColors.deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? SmartColors.vibrantCyan : color,
          width: isHighlighted ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isHighlighted ? SmartColors.vibrantCyan : color),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: SmartColors.vibrantCyan,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

