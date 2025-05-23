import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user's role
  Future<String> getUserRole() async {
    if (currentUser == null) return 'user';
    final doc =
        await _firestore.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      return doc.data()?['role'] ?? 'user';
    }
    return 'user';
  }

  // Login with email and password
  Future<UserCredential> login(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email and password
  Future<UserCredential> register(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Update user profile (e.g., name)
  Future<void> updateProfile(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
