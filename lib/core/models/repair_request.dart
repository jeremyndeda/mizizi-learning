import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class RepairRequest {
  final String id;
  final String requesterId;
  final String itemName;
  final String description;
  final String status; // pending, approved, declined, completed
  final DateTime createdAt;
  final String? reason;
  final String? estimation;
  final String? itemId;
  final String? location;

  RepairRequest({
    String? id,
    required this.requesterId,
    required this.itemName,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.reason,
    this.estimation,
    this.itemId,
    this.location,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'itemName': itemName,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'reason': reason,
      'estimation': estimation,
      'itemId': itemId,
      'location': location,
    };
  }

  factory RepairRequest.fromMap(Map<String, dynamic> map, String id) {
    return RepairRequest(
      id: id,
      requesterId: map['requesterId'] as String,
      itemName: map['itemName'] as String,
      description: map['description'] as String,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reason: map['reason'] as String?,
      estimation: map['estimation'] as String?,
      itemId: map['itemId'] as String?,
      location: map['location'] as String?,
    );
  }
}
