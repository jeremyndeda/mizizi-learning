import 'package:cloud_firestore/cloud_firestore.dart';

class ItemRequest {
  final String id;
  final String itemId;
  final String itemName; // New field to store the requested item name
  final int quantity;
  final String requesterId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? purpose; // Purpose of the request
  final String? reason; // Reason for rejection, if applicable
  final DateTime createdAt;

  ItemRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.requesterId,
    this.status = 'pending',
    this.purpose,
    this.reason,
    required this.createdAt,
  });

  factory ItemRequest.fromMap(Map<String, dynamic> map, String id) {
    return ItemRequest(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '', // Default to empty if null
      quantity: (map['quantity'] as int?) ?? 0,
      requesterId: map['requesterId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      purpose: map['purpose'] as String?,
      reason: map['reason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName, // Include new field in the map
      'quantity': quantity,
      'requesterId': requesterId,
      'status': status,
      'purpose': purpose,
      'reason': reason,
      'createdAt': createdAt,
    };
  }
}
