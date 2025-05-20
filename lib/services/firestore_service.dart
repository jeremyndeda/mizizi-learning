import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../models/activity_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc.data()!, uid) : null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  Future<void> createRequest(RequestModel request) async {
    try {
      await _firestore
          .collection('requests')
          .doc(request.id)
          .set(request.toFirestore());
    } catch (e) {
      print('Error creating request: $e');
      rethrow;
    }
  }

  Stream<List<RequestModel>> getUserRequests(String userId) {
    return _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => RequestModel.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<List<RequestModel>> getAllRequests() {
    return _firestore
        .collection('requests')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => RequestModel.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': status,
      });
    } catch (e) {
      print('Error updating request status: $e');
      rethrow;
    }
  }

  Future<void> createActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection('activities')
          .doc(activity.id)
          .set(activity.toFirestore());
    } catch (e) {
      print('Error creating activity: $e');
      rethrow;
    }
  }

  Stream<List<ActivityModel>> getUserActivities(String userId) {
    return _firestore
        .collection('activities')
        .where('assignedUsers', arrayContains: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }

  Stream<List<ActivityModel>> getAllActivities() {
    return _firestore
        .collection('activities')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ActivityModel.fromFirestore(doc.data(), doc.id))
                  .toList(),
        );
  }
}
