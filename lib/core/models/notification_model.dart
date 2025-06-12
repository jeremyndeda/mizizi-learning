import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String userId;
  final bool isRead;
  final String? type;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.userId,
    this.isRead = false,
    this.type,
    this.data,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
      isRead: map['isRead'] ?? false,
      type: map['type'] as String?,
      data:
          map['data'] != null
              ? Map<String, dynamic>.from(map['data'] as Map)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'isRead': isRead,
      'type': type,
      'data': data,
    };
  }
}
