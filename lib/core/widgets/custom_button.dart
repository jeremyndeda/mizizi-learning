import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Changed to nullable
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed, // Now nullable, not required
    this.isLoading = false,
    this.backgroundColor = AppColors.primaryGreen,
    this.foregroundColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        minimumSize: const Size(
          120,
          50,
        ), // Finite width to prevent layout issues
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child:
          isLoading
              ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: foregroundColor,
                  strokeWidth: 2,
                ),
              )
              : Text(
                text,
                style: AppTypography.buttonText.copyWith(
                  color: foregroundColor,
                ),
              ),
    );
  }
}
