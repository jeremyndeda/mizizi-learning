import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> assignedUsers;

  ActivityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.assignedUsers,
  });

  factory ActivityModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ActivityModel(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'startDate': startDate,
      'endDate': endDate,
      'assignedUsers': assignedUsers,
    };
  }
}
