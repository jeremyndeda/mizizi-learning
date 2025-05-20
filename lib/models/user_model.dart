class UserModel {
  final String uid;
  final String email;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] as String,
      role: data['role'] as String,
      createdAt: data['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'email': email, 'role': role, 'createdAt': createdAt};
  }
}
