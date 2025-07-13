import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/typography.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/user_model.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userEmails = await _firestoreService.getAllUserEmails();
      final users = <UserModel>[];
      for (final email in userEmails) {
        final user = await _firestoreService.getUserByEmail(email);
        if (user != null) {
          users.add(user);
        }
      }
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading users: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading users: $e',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers =
          _users.where((user) {
            final emailMatch = user.email.toLowerCase().contains(query);
            final nameMatch = user.name?.toLowerCase().contains(query) ?? false;
            return emailMatch || nameMatch;
          }).toList();
    });
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddUserDialog(
            onAddUser: (email, name, role) async {
              try {
                final userCredential = await _authService.createUserWithEmail(
                  email,
                  name: name,
                );
                final uid = userCredential.user!.uid;

                await _firestoreService.sendUserToFirestore(
                  uid,
                  email,
                  name: name.isNotEmpty ? name : null,
                  role: role,
                );

                await _authService.sendPasswordResetEmail(email);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'User created and password reset email sent',
                        style: AppTypography.bodyText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFF4CAF50),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }

                await _loadUsers();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error creating user: $e',
                        style: AppTypography.bodyText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Future<void> _updateUser(
    UserModel user,
    String newName,
    String newRole,
  ) async {
    try {
      await _firestoreService.updateUser(user.uid, {
        'name': newName.isNotEmpty ? newName : null,
        'role': newRole,
      });
      if (newName.isNotEmpty) {
        await _authService.updateProfile(newName);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User updated successfully',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating user: $e',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => EditUserDialog(
            user: user,
            onUpdate: (newName, newRole) => _updateUser(user, newName, newRole),
          ),
    );
  }

  Future<void> _resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to $email',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sending password reset email: $e',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showResetPasswordDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Reset Password', style: AppTypography.heading2),
            content: Text(
              'Are you sure you want to send a password reset email to ${user.email}?',
              style: AppTypography.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyText.copyWith(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _resetPassword(user.email);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Send', style: AppTypography.buttonText),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (_authService.currentUser?.uid == user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete your own account',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }

    try {
      await _firestoreService.deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${user.email} deleted successfully',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting user: $e',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteUserDialog(UserModel user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete User',
              style: AppTypography.heading2.copyWith(
                color: const Color(0xFFE57373),
              ),
            ),
            content: Text(
              'Are you sure you want to delete ${user.email}? This will remove their data, including inventory, requests, and activities. This action cannot be undone.',
              style: AppTypography.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyText.copyWith(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _deleteUser(user);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE57373),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Delete',
                  style: AppTypography.buttonText.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Manage Users',
          style: AppTypography.heading1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        backgroundColor: Colors.transparent,
        elevation: 3,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.person_add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 400),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by email or name',
                                  hintStyle: AppTypography.bodyText.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4CAF50),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                                style: AppTypography.bodyText,
                                onChanged: (_) => _filterUsers(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 400),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodyText.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child:
                              _filteredUsers.isEmpty
                                  ? AnimationConfiguration.staggeredList(
                                    position: 2,
                                    duration: const Duration(milliseconds: 400),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_off,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No users found',
                                                style: AppTypography.bodyText
                                                    .copyWith(
                                                      color: Colors.grey[600],
                                                      fontSize: 18,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Try adding a new user or adjusting your search.',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: Colors.grey[500],
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers[index];
                                      return AnimationConfiguration.staggeredList(
                                        position: index,
                                        duration: const Duration(
                                          milliseconds: 400,
                                        ),
                                        child: SlideAnimation(
                                          verticalOffset: 50.0,
                                          child: FadeInAnimation(
                                            child: UserCard(
                                              user: user,
                                              onEdit:
                                                  () =>
                                                      _showEditUserDialog(user),
                                              onResetPassword:
                                                  () =>
                                                      _showResetPasswordDialog(
                                                        user,
                                                      ),
                                              onDelete:
                                                  () => _showDeleteUserDialog(
                                                    user,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }
}

class AddUserDialog extends StatefulWidget {
  final Function(String email, String name, String role) onAddUser;

  const AddUserDialog({super.key, required this.onAddUser});

  @override
  _AddUserDialogState createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'user';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimationLimiter(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder:
                    (widget) => SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(child: widget),
                    ),
                children: [
                  Text(
                    'Add New User',
                    style: AppTypography.heading2.copyWith(
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: AppTypography.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.bodyText,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name (Optional)',
                      labelStyle: AppTypography.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: AppTypography.bodyText,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: AppTypography.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    style: AppTypography.bodyText,
                    items:
                        ['user', 'care', 'admin'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role.isNotEmpty
                                  ? '${role.substring(0, 1).toUpperCase()}${role.substring(1)}'
                                  : role,
                            ),
                          );
                        }).toList(),
                    onChanged:
                        (value) => setState(() => _selectedRole = value!),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            _isSubmitting
                                ? null
                                : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isSubmitting = true);
                                    await widget.onAddUser(
                                      _emailController.text.trim(),
                                      _nameController.text.trim(),
                                      _selectedRole,
                                    );
                                    setState(() => _isSubmitting = false);
                                    Navigator.pop(context);
                                  }
                                },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Add User',
                                    style: AppTypography.bodyText.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EditUserDialog extends StatefulWidget {
  final UserModel user;
  final Function(String newName, String newRole) onUpdate;

  const EditUserDialog({super.key, required this.user, required this.onUpdate});

  @override
  _EditUserDialogState createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _nameController = TextEditingController();
  String _selectedRole = 'user';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.name ?? '';
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimationLimiter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 400),
              childAnimationBuilder:
                  (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
              children: [
                Text(
                  'Edit User',
                  style: AppTypography.heading2.copyWith(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name (Optional)',
                    labelStyle: AppTypography.bodyText.copyWith(
                      color: Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4CAF50),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  style: AppTypography.bodyText,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: AppTypography.bodyText.copyWith(
                      color: Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF4CAF50),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                  ),
                  style: AppTypography.bodyText,
                  items:
                      ['user', 'care', 'admin'].map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role.isNotEmpty
                                ? '${role.substring(0, 1).toUpperCase()}${role.substring(1)}'
                                : role,
                          ),
                        );
                      }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: AppTypography.bodyText.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        widget.onUpdate(
                          _nameController.text.trim(),
                          _selectedRole,
                        );
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Save',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    radius: 24,
                    child: Text(
                      user.name != null && user.name!.isNotEmpty
                          ? user.name!.substring(0, 1).toUpperCase()
                          : user.email.substring(0, 1).toUpperCase(),
                      style: AppTypography.bodyText.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.email,
                          style: AppTypography.bodyText.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Name: ${user.name ?? 'N/A'} | Role: ${user.role.isNotEmpty ? '${user.role.substring(0, 1).toUpperCase()}${user.role.substring(1)}' : user.role}',
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 24),
                    onPressed: onEdit,
                    tooltip: 'Edit User',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.lock_reset,
                      color: Colors.orange,
                      size: 24,
                    ),
                    onPressed: onResetPassword,
                    tooltip: 'Reset Password',
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color(0xFFE57373),
                      size: 24,
                    ),
                    onPressed: onDelete,
                    tooltip: 'Delete User',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
