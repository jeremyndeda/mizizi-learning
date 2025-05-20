import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> sendUserToFirestore(String uid, String email) async {
  final usersRef = FirebaseFirestore.instance.collection('users');
  try {
    await usersRef.doc(uid).set({
      'uid': uid,
      'email': email,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  } catch (e) {
    print('Error sending user to Firestore: $e');
    return false;
  }
}
