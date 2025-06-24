import 'package:flutter/material.dart';
// ignore: unused_import
import '../constants/colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final bool enabled;
  final Widget? prefixIcon; // Added prefixIcon
  final int? maxLines; // Added maxLines

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.focusNode,
    this.suffixIcon,
    this.enabled = true,
    this.prefixIcon, // Added to constructor
    this.maxLines = 1, // Added to constructor with default value
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      focusNode: focusNode,
      enabled: enabled,
      maxLines: maxLines, // Added maxLines to TextField
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(fontSize: 16, color: Colors.black54),
        prefixIcon: prefixIcon, // Added prefixIcon to InputDecoration
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            enabled
                ? Colors.grey[100]
                : Colors.grey[100]?.withOpacity(
                  0.5,
                ), // Adjusted for inline style and null safety
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.green, // Replaced AppColors.primaryGreen
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
