import 'package:flutter/material.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: SmartColors.smartText,
        ),
      ),
    );
  }
}
