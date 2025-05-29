import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/item_request.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to get all inventory items
  Stream<List<InventoryItem>> getAllInventory() {
    return _firestore
        .collection('inventory')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Stream to get inventory items for a specific user
  Stream<List<InventoryItem>> getUserInventory(String userId) {
    return _firestore
        .collection('inventory')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Stream to get all item requests
  Stream<List<ItemRequest>> getAllItemRequests() {
    return _firestore
        .collection('requests')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ItemRequest.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Get a single inventory item by ID
  Future<InventoryItem?> getItemById(String id) async {
    if (id.isEmpty) {
      return null;
    }
    final doc = await _firestore.collection('inventory').doc(id).get();
    if (doc.exists) {
      return InventoryItem.fromMap(doc.data()!, id);
    }
    return null;
  }

  // Get a single user by ID
  Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) {
      return null;
    }
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Save user to Firestore
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

  // Send user to Firestore if not already there
  Future<void> sendUserToFirestoreIfNotExists(
    String uid,
    String email, {
    String? name,
    String role = 'user',
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await sendUserToFirestore(uid, email, name: name, role: role);
    }
  }

  // Get user data by UID

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    final querySnapshot =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      final doc = querySnapshot.docs.first;
      return UserModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ---------------- Inventory ----------------

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.collection('inventory').doc(item.id).set(item.toMap());
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection('inventory').doc(id).update(data);
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
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
    final endOfDay = startOfDay.add(const Duration(days: 1));

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

  Future<InventoryItem?> getItemByName(String name) async {
    final snapshot =
        await _firestore
            .collection('inventory')
            .where('name', isEqualTo: name)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return InventoryItem.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Future<List<String>> getAllInventoryItemNames() async {
    final snapshot = await _firestore.collection('inventory').get();
    return snapshot.docs
        .map((doc) => (doc.data()['name'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
  }

  // ---------------- Item Requests ----------------

  Future<void> addItemRequest(ItemRequest request) async {
    await _firestore
        .collection('item_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  Future<List<ItemRequest>> getFilteredItemRequests({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? requesterId,
  }) async {
    Query query = _firestore.collection('item_requests');

    if (startDate != null && endDate != null) {
      query = query
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status);
    }
    if (requesterId != null) {
      query = query.where('requesterId', isEqualTo: requesterId);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map(
          (doc) =>
              ItemRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Future<void> updateItemRequestStatus(
    String id,
    String status, {
    String? reason,
    String? itemId,
  }) async {
    final data = <String, dynamic>{'status': status};

    if (reason != null) data['reason'] = reason;
    if (itemId != null) data['itemId'] = itemId;

    await _firestore.collection('item_requests').doc(id).update(data);
  }

  // ---------------- Notifications ----------------

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

  // ---------------- User Search ----------------

  Future<List<UserModel>> searchUsersByEmailPrefix(String prefix) async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: prefix)
            .where('email', isLessThan: '${prefix}z')
            .limit(10)
            .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<String>> getAllUserEmails() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs
        .map((doc) => doc['email'] as String?)
        .where((email) => email != null)
        .cast<String>()
        .toList();
  }

  Future<List<UserModel>> searchUsersByEmail(String query) async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: query)
            .where('email', isLessThanOrEqualTo: '$query\uf8ff')
            .limit(10)
            .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<String>> searchUserEmails(String query) async {
    if (query.trim().isEmpty) return [];

    final snapshot = await _firestore.collection('users').get();

    return snapshot.docs
        .map((doc) => doc['email'] as String)
        .where((email) => email.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
