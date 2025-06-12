import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// Gets the current user's role from Firestore.
  /// Returns 'user' if no user is logged in or role is not found.
  Future<String> getUserRole() async {
    try {
      if (currentUser == null) return 'user';
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.exists ? (doc.data()?['role'] ?? 'user') : 'user';
    } catch (e) {
      print('Error fetching user role: $e');
      return 'user';
    }
  }

  /// Logs in a user with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await setLoggedInStatus(true);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Registers a new user with email and password.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> register(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await setLoggedInStatus(true);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Creates a new user with email, optional name, and a hardcoded initial password.
  /// Sends a password reset email to allow the user to set their own password.
  /// Sets the display name in Firebase Authentication if provided.
  /// Returns [UserCredential] on success.
  /// Throws [FirebaseAuthException] or [Exception] on failure.
  Future<UserCredential> createUserWithEmail(
    String email, {
    String? name,
  }) async {
    try {
      const initialPassword = 'InitialPass123!'; // Hardcoded initial password
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: initialPassword,
      );
      // Set display name if provided
      if (name != null && name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
      }
      // Send password reset email to encourage user to change the initial password
      await sendPasswordResetEmail(email.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception('User creation failed: $e');
    }
  }

  /// Sends a password reset email to the specified email address.
  /// Throws [FirebaseAuthException] or [Exception] on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  /// Deletes a user from Firebase Authentication by their UID.
  /// Note: The user must be recently signed in, or this will fail.
  /// Throws [FirebaseAuthException] or [Exception] on failure.
  Future<void> deleteUser(String uid) async {
    try {
      if (_auth.currentUser != null && _auth.currentUser!.uid == uid) {
        await _auth.currentUser!.delete();
      } else {
        throw Exception(
          'Deleting another user requires admin privileges. Use Firebase Admin SDK.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
          code: e.code,
          message: 'Please log in again to delete this account.',
        );
      }
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Updates the current user's display name.
  /// Throws [Exception] on failure.
  Future<void> updateProfile(String name) async {
    try {
      await _auth.currentUser?.updateDisplayName(name.trim());
      await _auth.currentUser?.reload();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Logs out the current user and updates login status.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await setLoggedInStatus(false);
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Sets the logged-in status in SharedPreferences.
  Future<void> setLoggedInStatus(bool status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', status);
    } catch (e) {
      print('Error setting logged-in status: $e');
    }
  }

  /// Gets the logged-in status from SharedPreferences.
  Future<bool> getLoggedInStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('loggedIn') ?? false;
    } catch (e) {
      print('Error getting logged-in status: $e');
      return false;
    }
  }

  /// Checks if a user is logged in by verifying SharedPreferences and Firebase Auth.
  Future<bool> isLoggedIn() async {
    try {
      return await getLoggedInStatus() && _auth.currentUser != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }
}
