import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/custom_button.dart';
import 'components/profile_info.dart';
import 'components/report_generator.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: AppTypography.heading2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ProfileInfo(userId: userId),
            const SizedBox(height: 24),
            ReportGenerator(userId: userId),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Logout',
              onPressed: onLogout,
              backgroundColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
