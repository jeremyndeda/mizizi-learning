import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;

    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await FirestoreService().markNotificationAsRead(notification.id);
        }
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color:
            isRead
                ? AppColors.white
                : AppColors.primaryGreen.withOpacity(0.9), // darker background
        child: ListTile(
          leading: Icon(
            Icons.notifications,
            color: isRead ? AppColors.grey : AppColors.white,
          ),
          title: Text(
            notification.title,
            style: AppTypography.bodyText.copyWith(
              color: isRead ? AppColors.black : AppColors.white,
            ),
          ),
          subtitle: Text(
            notification.body,
            style: AppTypography.caption.copyWith(
              color: isRead ? AppColors.grey : Colors.white70,
            ),
          ),
          trailing: Text(
            notification.createdAt.toString().split(' ')[0],
            style: AppTypography.caption.copyWith(
              color: isRead ? AppColors.grey : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}
