import 'package:cloud_firestore/cloud_firestore.dart';

class GeneralItem {
  final String id;
  final String name;
  final String packagingType;
  final String createdBy;
  final Timestamp createdAt;

  GeneralItem({
    required this.id,
    required this.name,
    required this.packagingType,
    required this.createdBy,
    required this.createdAt,
  });

  factory GeneralItem.fromMap(Map<String, dynamic> data, String id) {
    return GeneralItem(
      id: id,
      name: data['name'] ?? '',
      packagingType: data['packagingType'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packagingType': packagingType,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}
