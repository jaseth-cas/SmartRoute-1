import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/datos/mock_data.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

/// Diálogo interactivo que simula el Terminal de Reconocimiento Facial AI (Edge ML)
/// Rediseñado con estética Neumórfica de Alto Contraste y Minimalista Quivox.
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
    final waiting = MockData.passengers.where((p) => p.status == PassengerStatus.waiting).toList();
    _selectedStudent = widget.targetStudent ?? (waiting.isNotEmpty ? waiting.first : MockData.passengers.first);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(_animController);

    _startSimulatedRecognition();
  }

  void _startSimulatedRecognition() {
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _step = 1;
        });

        MockData.checkInPassenger(_selectedStudent.id, method: 'Biometría Facial AI');

        _timer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _step = 2;
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
          color: SmartColors.deepBlack, // Alto contraste Quivox
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: SmartColors.deepBlack.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
          border: Border.all(
            color: SmartColors.vibrantCyan.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra superior de la cámara
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _step == 2 ? SmartColors.vibrantCyan : SmartColors.primaryCrimson,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TERMINAL // AI BOARDING CAMERA',
                    style: GoogleFonts.jetBrainsMono(
                      color: SmartColors.ghostWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      widget.onBoardingCompleted();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: SmartColors.ghostWhite, size: 16),
                    ),
                  ),
                ],
              ),
            ),

            // Visor de Cámara Simulado con HUD Biométrico
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF091622),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _step >= 1 ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 110,
                    color: _step >= 1
                        ? SmartColors.vibrantCyan.withValues(alpha: 0.3)
                        : Colors.white12,
                  ),

                  // Bounding Box (Cuadro de detección facial)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _step >= 1 ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Línea láser animada mientras escanea
                        if (_step == 0)
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimation.value * 150,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: SmartColors.vibrantCyan,
                                    boxShadow: [
                                      BoxShadow(
                                        color: SmartColors.vibrantCyan.withValues(alpha: 0.9),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        if (_step >= 1)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: SmartColors.vibrantCyan,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: SmartColors.deepBlack, size: 32),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Tag de estado en la cámara
                  Positioned(
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: SmartColors.deepBlack.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _step >= 1 ? SmartColors.vibrantCyan : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _step == 0
                            ? 'ANALIZANDO PATRONES...'
                            : _step == 1
                                ? 'COINCIDENCIA ENCONTRADA'
                                : 'MATCH BIOMÉTRICO: 99.8%',
                        style: GoogleFonts.jetBrainsMono(
                          color: _step >= 1 ? SmartColors.vibrantCyan : SmartColors.ghostWhite,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tarjeta de información del alumno identificado
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SmartColors.vibrantCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: SmartColors.vibrantCyan, width: 1.5),
                        ),
                        child: const Icon(Icons.school_rounded, color: SmartColors.vibrantCyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedStudent.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: SmartColors.ghostWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_selectedStudent.schoolName} • ${_selectedStudent.busCode}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF091622),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TUTOR RESPONSABLE:',
                          style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 10.5),
                        ),
                        Text(
                          _selectedStudent.parentName,
                          style: GoogleFonts.plusJakartaSans(
                            color: SmartColors.ghostWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      widget.onBoardingCompleted();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _step == 2 ? SmartColors.vibrantCyan : SmartColors.deepBlue,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: (_step == 2 ? SmartColors.vibrantCyan : SmartColors.deepBlue)
                                .withValues(alpha: 0.35),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _step == 2 ? 'CONFIRMAR Y FINALIZAR' : 'CERRAR ESCANEO',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.8,
                          color: _step == 2 ? SmartColors.deepBlack : SmartColors.ghostWhite,
                        ),
                      ),
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
