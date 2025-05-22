import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/typography.dart';
import '../../../core/services/firestore_service.dart';

class WelcomeCard extends StatelessWidget {
  final String userId;
  final VoidCallback onNotificationsTap;

  const WelcomeCard({
    super.key,
    required this.userId,
    required this.onNotificationsTap,
  });

  /// Extracts a formatted name from the email.
  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final parts = localPart.split('.');
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getUser(userId),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
        final displayName =
            user.name?.isNotEmpty == true
                ? user.name
                : _nameFromEmail(user.email);

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $displayName!',
                      style: AppTypography.heading2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your inventory with ease',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications,
                    color: AppColors.primaryGreen,
                  ),
                  onPressed: onNotificationsTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
