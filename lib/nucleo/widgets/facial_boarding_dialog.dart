import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/servicios/attendance_service.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Diálogo interactivo que simula el Terminal de Reconocimiento Facial AI (Edge ML)
/// montado en el tablero del bus escolar.
class FacialBoardingDialog extends StatefulWidget {
  final StudentPassengerMock? targetStudent;
  final VoidCallback onBoardingCompleted;

  const FacialBoardingDialog({
    super.key,
    this.targetStudent,
    required this.onBoardingCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    StudentPassengerMock? targetStudent,
    required VoidCallback onBoardingCompleted,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FacialBoardingDialog(
        targetStudent: targetStudent,
        onBoardingCompleted: onBoardingCompleted,
      ),
    );
  }

  @override
  State<FacialBoardingDialog> createState() => _FacialBoardingDialogState();
}

class _FacialBoardingDialogState extends State<FacialBoardingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  int _step = 0; // 0: Escaneando, 1: Coincidencia, 2: Registrado
  late StudentPassengerMock _selectedStudent;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Si no se especificó un estudiante objetivo, tomamos el primer estudiante en espera
    final waiting = MockData.passengers.where((p) => p.status == PassengerStatus.waiting).toList();
    _selectedStudent = widget.targetStudent ?? (waiting.isNotEmpty ? waiting.first : MockData.passengers.first);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(_animController);

    // Simular el ciclo de reconocimiento facial local (Edge AI < 1.5s)
    _startSimulatedRecognition();
  }

  void _startSimulatedRecognition() {
    _timer = Timer(const Duration(milliseconds: 1600), () async {
      if (mounted) {
        setState(() {
          _step = 1; // Coincidencia encontrada
        });

        // Registrar abordaje real en PostgreSQL mediante AttendanceService
        try {
          final attendanceService = context.read<AttendanceService>();
          await attendanceService.checkInPassenger(
            studentId: _selectedStudent.id,
            method: 'Biometría Facial AI',
          );
        } catch (e) {
          debugPrint('Aviso registrando abordaje en Supabase: $e');
        }
        MockData.checkInPassenger(_selectedStudent.id, method: 'Biometría Facial AI');

        _timer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _step = 2; // Éxito total
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SmartColors.smartBlue.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior de la cámara
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _step == 2 ? SmartColors.smartGreen : SmartColors.smartRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'TERMINAL IA • CÁMARA TABLERO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                    onPressed: () {
                      widget.onBoardingCompleted();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // Visor de Cámara Simulado con HUD Biométrico
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _step == 1 || _step == 2 ? SmartColors.smartGreen : SmartColors.smartBlue,
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Patrón de cuadrícula de fondo
                  Icon(
                    Icons.face,
                    size: 130,
                    color: _step >= 1 ? SmartColors.smartGreen.withValues(alpha: 0.3) : Colors.white12,
                  ),

                  // Bounding Box (Cuadro de detección facial)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _step >= 1 ? SmartColors.smartGreen : SmartColors.smartBlue,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        // Esquinas resaltadas
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: SmartColors.smartBlue, borderRadius: BorderRadius.only(topLeft: Radius.circular(14)))),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: SmartColors.smartBlue, borderRadius: BorderRadius.only(topRight: Radius.circular(14)))),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: SmartColors.smartBlue, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)))),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: SmartColors.smartBlue, borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)))),
                        ),

                        // Línea láser animada mientras escanea
                        if (_step == 0)
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimation.value * 160,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: SmartColors.smartBlue,
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.smartBlue.withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // Icono de match completado
                        if (_step >= 1)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: SmartColors.smartGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 36),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tag de estado en la cámara
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _step == 0
                            ? 'Buscando rostro en visor...'
                            : _step == 1
                                ? 'Identificando embeddings...'
                                : 'Coincidencia Biométrica: 99.4%',
                        style: TextStyle(
                          color: _step >= 1 ? SmartColors.smartLightGreen : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tarjeta de información del alumno identificado
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SmartColors.smartLightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: SmartColors.smartBlue),
                        ),
                        child: const Icon(Icons.school, color: SmartColors.smartBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedStudent.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_selectedStudent.schoolName} • ${_selectedStudent.pickupAddress}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tutor avisado por push:',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        Text(
                          _selectedStudent.parentName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _step == 2 ? SmartColors.smartGreen : SmartColors.smartBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      widget.onBoardingCompleted();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(_step == 2 ? Icons.done_all : Icons.camera_alt),
                    label: Text(
                      _step == 2 ? 'Abordaje Confirmado' : 'Finalizar Escaneo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
