import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String name;
  final String? condition;
  final String category;
  final String userId;
  final String? userEmail;
  final DateTime createdAt;
  final String? description;
  final String? location;
  final int amount;

  InventoryItem({
    required this.id,
    required this.name,
    this.condition,
    required this.category,
    required this.userId,
    this.userEmail,
    required this.createdAt,
    this.description,
    this.location,
    this.amount = 1,
  });

  factory InventoryItem.fromMap(Map<String, dynamic> map, String id) {
    return InventoryItem(
      id: id,
      name: map['name'] ?? '',
      condition: map['condition'],
      category: map['category'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      description: map['description'],
      location: map['location'],
      amount: (map['amount'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'condition': condition,
      'category': category,
      'userId': userId,
      'userEmail': userEmail,
      'createdAt': createdAt,
      'description': description,
      'location': location,
      'amount': amount,
    };
  }
}
