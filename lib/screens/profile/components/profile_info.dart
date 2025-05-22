import 'package:flutter/material.dart';
import '../../../core/constants/typography.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class ProfileInfo extends StatefulWidget {
  final String userId;

  const ProfileInfo({super.key, required this.userId});

  @override
  _ProfileInfoState createState() => _ProfileInfoState();
}

class _ProfileInfoState extends State<ProfileInfo> {
  final _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await _firestoreService.getUser(widget.userId);
    if (user != null) {
      _nameController.text = user.name ?? '';
    }
  }

  void _updateProfile() async {
    await _authService.updateProfile(_nameController.text.trim());
    await _firestoreService.updateUser(widget.userId, {
      'name': _nameController.text.trim(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _firestoreService.getUser(widget.userId),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Information', style: AppTypography.heading2),
                const SizedBox(height: 16),
                CustomTextField(controller: _nameController, labelText: 'Name'),
                const SizedBox(height: 16),
                Text('Email: ${user.email}', style: AppTypography.bodyText),
                const SizedBox(height: 8),
                Text('Role: ${user.role}', style: AppTypography.bodyText),
                const SizedBox(height: 16),
                CustomButton(text: 'Update Profile', onPressed: _updateProfile),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
