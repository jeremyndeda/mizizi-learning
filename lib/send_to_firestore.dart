import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendUserToFirestore(String uid, String email) async {
  final usersRef = FirebaseFirestore.instance.collection('users');

  await usersRef.doc(uid).set({
    'uid': uid,
    'email': email,
    'role': 'user', // Default role
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true)); // merge to avoid overwriting if exists
}
