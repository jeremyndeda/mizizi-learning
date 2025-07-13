import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String description;
  final String teacherId;
  final List<String> studentIds;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.studentIds,
    required this.createdAt,
  });

  factory Activity.fromMap(Map<String, dynamic> data, String id) {
    return Activity(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      teacherId: data['teacherId'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
