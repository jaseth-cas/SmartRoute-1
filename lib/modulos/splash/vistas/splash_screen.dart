import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/widgets/neumorphic_box.dart';
import 'package:smartroute_flutter/nucleo/widgets/primary_button.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onStartClick;

  const SplashScreen({super.key, required this.onStartClick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartColors.neuBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Barra técnica superior minimalista
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SmartColors.deepBlack,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'SMARTROUTE // V1.0',
                      style: GoogleFonts.jetBrainsMono(
                        color: SmartColors.vibrantCyan,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: SmartColors.neuInset,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: SmartColors.vibrantCyan,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SYSTEM ONLINE',
                          style: GoogleFonts.jetBrainsMono(
                            color: SmartColors.deepBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Logo Neumórfico Central Esculpido
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NeumorphicBox(
                    width: 200,
                    height: 200,
                    borderRadius: BorderRadius.circular(50),
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo2.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'SmartRoute',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: SmartColors.deepBlack,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Monitoreo inteligente, biometría facial\ny optimización de transporte escolar',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      height: 1.4,
                      color: SmartColors.smartGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Indicador de pasos estilo Quivox ("12/34")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: SmartColors.neuInset,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 5,
                          decoration: BoxDecoration(
                            color: SmartColors.deepBlack,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightGray,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 5,
                          decoration: BoxDecoration(
                            color: SmartColors.smartLightGray,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Botón Cápsula Oscura Quivox
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: PrimaryButton(
                  text: 'INICIAR EXPERIENCIA',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onStartClick,
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
}
