import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'firestore_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final Logger _logger = Logger('NotificationService');

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      _logger.info(
        'Notification permission status: ${settings.authorizationStatus}',
      );

      // Get and store FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        _logger.info('FCM Token: $token');
        // Optionally store token in Firestore for the user
        // Example: await _firestoreService.updateUserToken(userId, token);
      }

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _logger.info('FCM Token refreshed: $newToken');
        // Update token in Firestore
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleMessage(message, isForeground: true);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

      // Handle messages when app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleMessage(message, isForeground: false);
      });

      // Get initial message (if app was opened from a terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage, isForeground: false);
      }
    } catch (e) {
      _logger.severe('Error initializing notifications: $e');
    }
  }

  void _handleMessage(RemoteMessage message, {required bool isForeground}) {
    try {
      if (message.notification != null) {
        final notification = NotificationModel(
          id: const Uuid().v4(),
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          createdAt: DateTime.now(),
          userId: message.data['userId'] ?? '',
          isRead: false,
        );
        _firestoreService.addNotification(notification);
        _logger.info(
          'Processed ${isForeground ? 'foreground' : 'background'} notification: ${notification.title}',
        );
      }
    } catch (e) {
      _logger.severe('Error handling message: $e');
    }
  }

  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    final firestoreService = FirestoreService();
    try {
      if (message.notification != null) {
        final notification = NotificationModel(
          id: const Uuid().v4(),
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          createdAt: DateTime.now(),
          userId: message.data['userId'] ?? '',
          isRead: false,
        );
        await firestoreService.addNotification(notification);
      }
    } catch (e) {
      // Cannot use Logger in background handler; use print for debugging
      print('Error in background message handler: $e');
    }
  }

  // Send notification for inventory updates
  Future<void> sendInventoryNotification(
    String userId,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        userId: userId,
        isRead: false,
        type: type,
        data: data,
      );
      await _firestoreService.addNotification(notification);
      _logger.info('Sent notification to user $userId: $title');
    } catch (e) {
      _logger.severe('Error sending notification: $e');
      rethrow;
    }
  }

  // Send notification to multiple users
  Future<void> sendInventoryNotificationToUsers(
    List<String> userIds,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      for (final userId in userIds) {
        await sendInventoryNotification(
          userId,
          title,
          body,
          type: type,
          data: data,
        );
      }
      _logger.info('Sent notification to ${userIds.length} users: $title');
    } catch (e) {
      _logger.severe('Error sending notifications to multiple users: $e');
      rethrow;
    }
  }
}
