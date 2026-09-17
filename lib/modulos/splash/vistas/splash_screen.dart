import 'package:flutter/material.dart';
import '../components/primary_button.dart';
import '../theme/colors.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onStartClick;

  const SplashScreen({super.key, required this.onStartClick});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              // Logo
              Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias, // Ensure image stays within circle
                child: Image.asset(
                  'assets/images/logo2.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
              Column(
                children: [
                  const Text(
                    'SmartRoute',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: SmartColors.smartBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Monitoreo inteligente de\nbuses universitarios',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.3,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Pagination dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(color: SmartColors.smartBlue, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: PrimaryButton(
                  text: 'Comenzar',
                  icon: Icons.arrow_forward,
                  onPressed: onStartClick,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
