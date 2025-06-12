import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';

class ReturnItemScreen extends StatefulWidget {
  const ReturnItemScreen({super.key});

  @override
  _ReturnItemScreenState createState() => _ReturnItemScreenState();
}

class _ReturnItemScreenState extends State<ReturnItemScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  InventoryItem? _selectedItem;
  UserModel? _selectedAdmin;
  List<InventoryItem> _userInventory = [];
  List<UserModel> _admins = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.uid;
      final inventory = await _firestoreService.getUserInventory(userId).first;
      final users = await _firestoreService.getAllUserEmails();
      final adminUsers = <UserModel>[];
      for (final email in users) {
        final user = await _firestoreService.getUserByEmail(email);
        if (user != null && user.role == 'admin') {
          adminUsers.add(user);
        }
      }

      setState(() {
        _userInventory = inventory;
        _admins = adminUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading data: $e',
              style: AppTypography.bodyText,
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

  Future<void> _returnItem() async {
    if (_selectedItem == null || _selectedAdmin == null) {
      setState(() {
        _errorMessage = 'Please select an item and an admin';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select an item and an admin',
              style: AppTypography.bodyText,
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

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Confirm Return',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Are you sure you want to return "${_selectedItem!.name}" to ${_selectedAdmin!.email}?',
                      style: AppTypography.bodyText.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyText.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pop(context, true),
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
                              'Confirm',
                              style: AppTypography.bodyText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _firestoreService.updateInventoryItem(_selectedItem!.id, {
        'userId': _selectedAdmin!.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "${_selectedItem!.name}" returned successfully',
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

      await _loadData();

      setState(() {
        _selectedItem = null;
        _selectedAdmin = null;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error returning item: $e';
        _isSubmitting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error returning item: $e',
              style: AppTypography.bodyText,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Return Item', style: AppTypography.heading1),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimationLimiter(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: AnimationConfiguration.toStaggeredList(
                            duration: const Duration(milliseconds: 375),
                            childAnimationBuilder:
                                (widget) => SlideAnimation(
                                  verticalOffset: 20.0,
                                  child: FadeInAnimation(child: widget),
                                ),
                            children: [
                              Text(
                                'Return an Item',
                                style: AppTypography.heading2.copyWith(
                                  color: const Color(0xFF4CAF50),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select Item to Return',
                                style: AppTypography.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<InventoryItem>(
                                value: _selectedItem,
                                hint: Text(
                                  'Choose an item',
                                  style: AppTypography.bodyText.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                isExpanded: true,
                                decoration: InputDecoration(
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
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                style: AppTypography.bodyText,
                                items:
                                    _userInventory.map((item) {
                                      return DropdownMenuItem<InventoryItem>(
                                        value: item,
                                        child: Text(
                                          item.name,
                                          style: AppTypography.bodyText,
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    _isSubmitting
                                        ? null
                                        : (value) {
                                          setState(() {
                                            _selectedItem = value;
                                            _errorMessage = null;
                                          });
                                        },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Select Admin to Return To',
                                style: AppTypography.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<UserModel>(
                                value: _selectedAdmin,
                                hint: Text(
                                  'Choose an admin',
                                  style: AppTypography.bodyText.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                                isExpanded: true,
                                decoration: InputDecoration(
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
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                style: AppTypography.bodyText,
                                items:
                                    _admins.map((admin) {
                                      return DropdownMenuItem<UserModel>(
                                        value: admin,
                                        child: Text(
                                          admin.email,
                                          style: AppTypography.bodyText,
                                        ),
                                      );
                                    }).toList(),
                                onChanged:
                                    _isSubmitting
                                        ? null
                                        : (value) {
                                          setState(() {
                                            _selectedAdmin = value;
                                            _errorMessage = null;
                                          });
                                        },
                              ),
                              const SizedBox(height: 16),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodyText.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              Center(
                                child: GestureDetector(
                                  onTap: _isSubmitting ? null : _returnItem,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4CAF50),
                                          Color(0xFF66BB6A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
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
                                              'Return Item',
                                              textAlign: TextAlign.center,
                                              style: AppTypography.bodyText
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                  ),
                                ),
                              ),
                              if (_userInventory.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Center(
                                    child: Text(
                                      'No items in your inventory to return',
                                      style: AppTypography.bodyText.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
