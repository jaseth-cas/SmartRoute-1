import 'package:flutter/material.dart';
import '../tema/colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextEditingController? controller;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: SmartColors.smartText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16, color: SmartColors.smartText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SmartColors.smartGray),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: SmartColors.smartGray, size: 20)
                : null,
            filled: true,
            fillColor: SmartColors.smartSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SmartColors.smartBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SmartColors.smartBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SmartColors.smartBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SmartColors.smartRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: SmartColors.smartRed, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
