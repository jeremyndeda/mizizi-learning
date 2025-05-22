import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor:
          notification.isRead
              ? AppColors.white
              : AppColors.secondaryGreen.withOpacity(0.1),
      leading: Icon(
        Icons.notifications,
        color: notification.isRead ? AppColors.grey : AppColors.primaryGreen,
      ),
      title: Text(notification.title, style: AppTypography.bodyText),
      subtitle: Text(notification.body, style: AppTypography.caption),
      onTap: onTap,
    );
  }
}
