import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final DateTime createdAt;
  final String? name;
  final List<String> linkedUserIds; // New field for linked accounts

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.createdAt,
    this.name,
    this.linkedUserIds = const [], // Default to empty list
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      name: map['name'],
      linkedUserIds: List<String>.from(map['linkedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'name': name,
      'linkedUserIds': linkedUserIds,
    };
  }
}
