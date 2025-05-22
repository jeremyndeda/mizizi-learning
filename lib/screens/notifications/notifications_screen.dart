import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser!.uid;
    final FirestoreService _firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: AppTypography.heading2),
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _firestoreService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('requires an index')) {
              return const Center(
                child: Text('Please wait, setting up notifications...'),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications available.'));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    notification.title,
                    style: AppTypography.bodyText,
                  ),
                  subtitle: Text(
                    notification.body,
                    style: AppTypography.caption,
                  ),
                  trailing: Text(
                    notification.createdAt.toString().split(' ')[0],
                    style: AppTypography.caption,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
