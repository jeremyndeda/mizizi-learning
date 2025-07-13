import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String className;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.createdAt,
  });

  factory Student.fromMap(Map<String, dynamic> data, String id) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      className: data['className'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'className': className,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
