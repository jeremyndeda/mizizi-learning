import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String userId;
  final String type;
  final String description;
  final String priority;
  final String? relatedItem;
  final String status;
  final DateTime createdAt;

  RequestModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.priority,
    this.relatedItem,
    required this.status,
    required this.createdAt,
  });

  factory RequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RequestModel(
      id: id,
      userId: data['userId'] as String,
      type: data['type'] as String,
      description: data['description'] as String,
      priority: data['priority'] as String,
      relatedItem: data['relatedItem'] as String?,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'description': description,
      'priority': priority,
      'relatedItem': relatedItem,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
