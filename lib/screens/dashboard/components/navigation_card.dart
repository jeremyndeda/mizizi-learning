import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';

class NavigationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor; // Added backgroundColor parameter

  const NavigationCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.backgroundColor, // Made backgroundColor required
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure full width
      constraints: const BoxConstraints(
        maxWidth: 600,
      ), // Limit for larger screens
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: backgroundColor, // Apply the background color to the card
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 40),
                const SizedBox(height: 8),
                Text(title, style: AppTypography.bodyText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
