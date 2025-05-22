import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'firestore_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // Request permission for notifications
    await _messaging.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final notification = NotificationModel(
          id: const Uuid().v4(),
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          createdAt: DateTime.now(),
          userId: message.data['userId'] ?? '',
        );
        _firestoreService.addNotification(notification);
      }
    });
  }

  // Send notification for inventory updates
  Future<void> sendInventoryNotification(
    String userId,
    String title,
    String body,
  ) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      userId: userId,
    );
    await _firestoreService.addNotification(notification);
  }
}
