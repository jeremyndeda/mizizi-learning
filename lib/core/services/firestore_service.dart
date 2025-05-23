import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user to Firestore (always writes or updates)
  Future<void> sendUserToFirestore(
    String uid,
    String email, {
    String? name,
    String role = 'user',
  }) async {
    final usersRef = _firestore.collection('users');
    await usersRef.doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ NEW: Save only if user doesn't already exist
  Future<void> sendUserToFirestoreIfNotExists(String uid, String email) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user data by UID
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final querySnapshot =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
    if (querySnapshot.docs.isNotEmpty) {
      return UserModel.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    }
    return null;
  }

  // Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Inventory Management
  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.collection('inventory').doc(item.id).set(item.toMap());
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection('inventory').doc(id).update(data);
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
  }

  Stream<List<InventoryItem>> getAllInventory() {
    return _firestore.collection('inventory').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<InventoryItem>> getUserInventory(String userId) {
    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<List<InventoryItem>> getInventoryByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot =
        await _firestore
            .collection('inventory')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

    return snapshot.docs
        .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<InventoryItem>> getInventoryByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    final snapshot =
        await _firestore
            .collection('inventory')
            .where(
              'createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
            )
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    return snapshot.docs
        .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Notifications
  Future<void> addNotification(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> markNotificationAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({
      'isRead': true,
    });
  }
}
