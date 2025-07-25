import 'package:Mizizi/core/models/activity_register.dart';
import 'package:Mizizi/core/models/repair_request.dart';
import 'package:Mizizi/core/models/student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/inventory_item.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../models/item_request.dart';
import '../models/general_item.dart';
import '../models/activity.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification for inventory updates
  Future<void> sendInventoryNotification(
    String userId,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
        userId: userId,
        isRead: false,
        type: type,
        data: data,
      );
      await addNotification(notification);
    } catch (e) {
      throw Exception('Error sending notification: $e');
    }
  }

  // Send notification to multiple users
  Future<void> sendInventoryNotificationToUsers(
    List<String> userIds,
    String title,
    String body, {
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      for (final userId in userIds) {
        await sendInventoryNotification(
          userId,
          title,
          body,
          type: type,
          data: data,
        );
      }
    } catch (e) {
      throw Exception('Error sending notifications to multiple users: $e');
    }
  }

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

  // Stream to get inventory items for a user and their linked users
  Stream<List<InventoryItem>> getUserInventory(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((
      userDoc,
    ) async {
      final userData = userDoc.data();
      if (userData == null) return [];

      final linkedUserIds = List<String>.from(userData['linkedUserIds'] ?? []);
      final allUserIds = [userId, ...linkedUserIds];

      final snapshot =
          await _firestore
              .collection('inventory')
              .where('userId', whereIn: allUserIds)
              .get();

      return snapshot.docs
          .map((doc) => InventoryItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Stream to get all item requests
  Stream<List<ItemRequest>> getAllItemRequests() {
    return _firestore
        .collection('item_requests')
        .withConverter<ItemRequest>(
          fromFirestore:
              (snapshot, _) =>
                  ItemRequest.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (item, _) => item.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Stream to get filtered item requests
  Stream<List<ItemRequest>> streamFilteredItemRequests({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? requesterId,
  }) {
    Query<ItemRequest> query = _firestore
        .collection('item_requests')
        .withConverter<ItemRequest>(
          fromFirestore:
              (snapshot, _) =>
                  ItemRequest.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (item, _) => item.toMap(),
        );

    if (requesterId != null) {
      query = query.where('requesterId', isEqualTo: requesterId);
    }
    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }
    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
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
    List<String> linkedUserIds = const [],
  }) async {
    final usersRef = _firestore.collection('users');
    await usersRef.doc(uid).set({
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'linkedUserIds': linkedUserIds,
    }, SetOptions(merge: true));
  }

  // Send user to Firestore if not already there
  Future<void> sendUserToFirestoreIfNotExists(
    String uid,
    String email, {
    String? name,
    String role = 'user',
    List<String> linkedUserIds = const [],
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      await sendUserToFirestore(
        uid,
        email,
        name: name,
        role: role,
        linkedUserIds: linkedUserIds,
      );
    }
  }

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

  // Get all admin users
  Future<List<UserModel>> getAdminUsers() async {
    final snapshot =
        await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Add linked user
  Future<void> linkUserAccount(String userId, String linkedUserId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final currentLinkedIds = List<String>.from(
        userDoc.data()!['linkedUserIds'] ?? [],
      );
      if (!currentLinkedIds.contains(linkedUserId)) {
        currentLinkedIds.add(linkedUserId);
        await _firestore.collection('users').doc(userId).update({
          'linkedUserIds': currentLinkedIds,
        });
      }
    }
  }

  // Remove linked user
  Future<void> unlinkUserAccount(String userId, String linkedUserId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final currentLinkedIds = List<String>.from(
        userDoc.data()!['linkedUserIds'] ?? [],
      );
      if (currentLinkedIds.contains(linkedUserId)) {
        currentLinkedIds.remove(linkedUserId);
        await _firestore.collection('users').doc(userId).update({
          'linkedUserIds': currentLinkedIds,
        });
      }
    }
  }

  // Delete user and related data
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user document
      await _firestore.collection('users').doc(uid).delete();

      // Delete user's notifications
      final notificationsSnapshot =
          await _firestore
              .collection('notifications')
              .where('userId', isEqualTo: uid)
              .get();
      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove user from linkedUserIds in other users
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('linkedUserIds', arrayContains: uid)
              .get();
      for (var doc in usersSnapshot.docs) {
        final linkedUserIds = List<String>.from(
          doc.data()['linkedUserIds'] ?? [],
        );
        linkedUserIds.remove(uid);
        await doc.reference.update({'linkedUserIds': linkedUserIds});
      }

      // Delete user's inventory items
      final inventorySnapshot =
          await _firestore
              .collection('inventory')
              .where('userId', isEqualTo: uid)
              .get();
      for (var doc in inventorySnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's item requests
      final itemRequestsSnapshot =
          await _firestore
              .collection('item_requests')
              .where('requesterId', isEqualTo: uid)
              .get();
      for (var doc in itemRequestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's repair requests
      final repairRequestsSnapshot =
          await _firestore
              .collection('repair_requests')
              .where('requesterId', isEqualTo: uid)
              .get();
      for (var doc in repairRequestsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user's activities and associated registers
      final activitiesSnapshot =
          await _firestore
              .collection('activities')
              .where('teacherId', isEqualTo: uid)
              .get();
      for (var doc in activitiesSnapshot.docs) {
        final activityId = doc.id;
        final registersSnapshot =
            await _firestore
                .collection('registers')
                .where('activityId', isEqualTo: activityId)
                .get();
        for (var regDoc in registersSnapshot.docs) {
          await regDoc.reference.delete();
        }
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // ---------------- Inventory ----------------

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.collection('inventory').doc(item.id).set(item.toMap());
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    final itemDoc = await _firestore.collection('inventory').doc(id).get();
    if (itemDoc.exists) {
      final currentItem = InventoryItem.fromMap(itemDoc.data()!, id);
      final newAmount = data['amount'] as int? ?? currentItem.amount;
      await _firestore.collection('inventory').doc(id).update(data);

      // Check for low stock and notify admins
      final newThreshold =
          data['lowStockThreshold'] as int? ?? currentItem.lowStockThreshold;
      if (newAmount <= newThreshold) {
        final admins = await getAdminUsers();
        await sendInventoryNotificationToUsers(
          admins.map((admin) => admin.uid).toList(),
          'Low Stock Alert',
          'Item ${currentItem.name} has reached low stock (Amount: $newAmount, Threshold: $newThreshold).',
          type: 'low_stock',
          data: {'itemId': id},
        );
      }
    }
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
            .where(
              'createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay),
            )
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

  Future<void> deleteItemRequest(String id) async {
    await _firestore.collection('item_requests').doc(id).delete();
  }

  // ---------------- Repair Requests ----------------

  Future<void> addRepairRequest(RepairRequest request) async {
    await _firestore
        .collection('repair_requests')
        .doc(request.id)
        .set(request.toMap());
  }

  Stream<List<RepairRequest>> getAllRepairRequests() {
    return _firestore
        .collection('repair_requests')
        .withConverter<RepairRequest>(
          fromFirestore:
              (snapshot, _) =>
                  RepairRequest.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (repair, _) => repair.toMap(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<RepairRequest>> streamFilteredRepairRequests({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? requesterId,
  }) {
    Query<RepairRequest> query = _firestore
        .collection('repair_requests')
        .withConverter<RepairRequest>(
          fromFirestore:
              (snapshot, _) =>
                  RepairRequest.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (repair, _) => repair.toMap(),
        );

    if (requesterId != null) {
      query = query.where('requesterId', isEqualTo: requesterId);
    }
    if (status != null && status != 'All') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }
    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateRepairRequestStatus(
    String id,
    String status, {
    String? reason,
    String? estimation,
    String? itemId,
  }) async {
    final data = <String, dynamic>{'status': status};

    if (reason != null) data['reason'] = reason;
    if (estimation != null) data['estimation'] = estimation;
    if (itemId != null) data['itemId'] = itemId;

    await _firestore.collection('repair_requests').doc(id).update(data);
  }

  Future<void> deleteRepairRequest(String id) async {
    await _firestore.collection('repair_requests').doc(id).delete();
  }

  Future<RepairRequest?> getRepairRequestById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection('repair_requests').doc(id).get();
    if (doc.exists) {
      return RepairRequest.fromMap(doc.data()!, id);
    }
    return null;
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

  // ---------------- General Items ----------------

  Future<void> addGeneralItem(GeneralItem item) async {
    await _firestore.collection('general_items').doc(item.id).set(item.toMap());
  }

  Future<void> updateGeneralItem(String id, Map<String, dynamic> data) async {
    await _firestore.collection('general_items').doc(id).update(data);
  }

  Future<void> deleteGeneralItem(String id) async {
    await _firestore.collection('general_items').doc(id).delete();
  }

  Stream<List<GeneralItem>> getAllGeneralItems() {
    return _firestore
        .collection('general_items')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => GeneralItem.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<GeneralItem?> getGeneralItemById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection('general_items').doc(id).get();
    if (doc.exists) {
      return GeneralItem.fromMap(doc.data()!, id);
    }
    return null;
  }

  // ---------------- Students ----------------

  Future<void> addStudent(Student student) async {
    await _firestore
        .collection('students')
        .doc(student.id)
        .set(student.toMap());
  }

  Stream<List<Student>> getAllStudents() {
    return _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Student.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) async {
    await _firestore.collection('students').doc(id).update(data);
  }

  Future<void> deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }

  Future<Student?> getStudentById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection('students').doc(id).get();
    if (doc.exists) {
      return Student.fromMap(doc.data()!, id);
    }
    return null;
  }

  // ---------------- Activities ----------------

  Future<void> addActivity(Activity activity) async {
    await _firestore
        .collection('activities')
        .doc(activity.id)
        .set(activity.toMap());
  }

  Stream<List<Activity>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('teacherId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Activity.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> updateActivity(String id, Map<String, dynamic> data) async {
    await _firestore.collection('activities').doc(id).update(data);
  }

  Future<void> deleteActivity(String id) async {
    await _firestore.collection('activities').doc(id).delete();
  }

  Future<Activity?> getActivityById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection('activities').doc(id).get();
    if (doc.exists) {
      return Activity.fromMap(doc.data()!, id);
    }
    return null;
  }

  Future<void> addActivityRegister(ActivityRegister register) async {
    await _firestore
        .collection('registers')
        .doc(register.id)
        .set(register.toMap());
  }

  Future<void> deleteActivityRegister(String id) async {
    await _firestore.collection('registers').doc(id).delete();
  }

  // Updated getAllActivities to ensure no teacherId filter for admins
  Stream<List<Activity>> getAllActivities() {
    return _firestore
        .collection('activities')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Activity.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  // Check if user is assigned as teacher to an activity
  Future<bool> isUserTeacherForActivity(
    String activityId,
    String userId,
  ) async {
    final doc = await _firestore.collection('activities').doc(activityId).get();
    if (!doc.exists) return false;
    final activity = Activity.fromMap(doc.data()!, doc.id);
    return activity.teacherId == userId;
  }

  Stream<List<ActivityRegister>> getActivityRegisters(String activityId) {
    return _firestore
        .collection('registers')
        .where('activityId', isEqualTo: activityId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ActivityRegister.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
