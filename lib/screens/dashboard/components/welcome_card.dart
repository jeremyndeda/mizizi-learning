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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirestoreService().getUser(userId),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = snapshot.data;
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
                      'Welcome, ${user.name ?? user.email}!',
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
