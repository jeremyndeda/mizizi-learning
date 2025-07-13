import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityRegister {
  final String id;
  final String activityId;
  final DateTime date;
  final Map<String, bool> attendance; // studentId: isPresent
  final DateTime createdAt;

  ActivityRegister({
    required this.id,
    required this.activityId,
    required this.date,
    required this.attendance,
    required this.createdAt,
  });

  factory ActivityRegister.fromMap(Map<String, dynamic> data, String id) {
    return ActivityRegister(
      id: id,
      activityId: data['activityId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attendance: Map<String, bool>.from(data['attendance'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'date': Timestamp.fromDate(date),
      'attendance': attendance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} // TODO Implement this library.
