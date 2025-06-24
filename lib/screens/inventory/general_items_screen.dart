import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/typography.dart';
import '../../core/models/general_item.dart';
import '../../core/models/item_request.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/pdf_service.dart';

class GeneralItemsScreen extends StatefulWidget {
  const GeneralItemsScreen({super.key});

  @override
  _GeneralItemsScreenState createState() => _GeneralItemsScreenState();
}

class _GeneralItemsScreenState extends State<GeneralItemsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final PdfService _pdfService = PdfService();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _packagingTypeController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _selectedItems = {};
  final Map<String, TextEditingController> _quantityControllers = {};
  String _role = 'user';
  bool _isAddingItem = false;
  bool _isEditingItem = false;
  String? _editingItemId;
  DateTimeRange? _dateRange;
  String? _selectedUserId;
  String? _selectedUserName;
  bool _isLoading = false;

  final List<String> _packagingTypes = [
    'Piece',
    'Unit',
    'Packet',
    'Pouch',
    'Sachet',
    'Tube',
    'Stick',
    'Strip',
    'Pair',
    'Set',
    'Kit',
    'Blister Pack',
    'Bundle',
    'Dozen',
    'Half Dozen',
    'Score',
    'Gross',
    'Pack',
    'Multipack',
    'Carton',
    'Case',
    'Tray',
    'Crate',
    'Shrink Wrap Pack',
    'Display Box',
    'Pallet',
    'Skid',
    'Drum',
    'Barrel',
    'Sack',
    'Bag',
    'Bulk Bin',
    'Tote',
    'Container',
    'Ream',
    'Bale',
    'Roll',
    'Coil',
    'Slab',
    'Block',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserRole() async {
    setState(() => _isLoading = true);
    final role = await _authService.getUserRole();
    setState(() {
      _role = role;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder:
          (context, pickerChild) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4CAF50),
                onPrimary: Colors.white,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: Color(0xFF4CAF50)),
              ),
              dialogTheme: DialogThemeData(backgroundColor: Colors.white),
            ),
            child: Dialog(
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
                        'Select Date Range',
                        textAlign: TextAlign.center,
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: pickerChild,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _selectUser() async {
    final users = await _firestoreService.searchUsersByEmail('');
    showDialog(
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
                      'Select User',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 400),
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(
                                    0xFF4CAF50,
                                  ).withOpacity(0.1),
                                  child: Text(
                                    user.name?.substring(0, 1).toUpperCase() ??
                                        'U',
                                    style: AppTypography.bodyText.copyWith(
                                      color: const Color(0xFF4CAF50),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.email,
                                  style: AppTypography.bodyText,
                                ),
                                subtitle:
                                    user.name != null
                                        ? Text(
                                          user.name!,
                                          style: AppTypography.caption,
                                        )
                                        : null,
                                onTap: () {
                                  setState(() {
                                    _selectedUserId = user.uid;
                                    _selectedUserName = user.name ?? user.email;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserId = null;
                              _selectedUserName = null;
                            });
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
                              'All Users',
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
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      await _pdfService.generateGeneralItemsReport(
        userId: _selectedUserId,
        userName: _selectedUserName,
        dateRange:
            _dateRange == null ? null : [_dateRange!.start, _dateRange!.end],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Report generated successfully',
              style: AppTypography.bodyText,
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
              'Failed to generate report: $e',
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addOrEditItem({GeneralItem? item}) async {
    if (_itemNameController.text.trim().isEmpty ||
        _packagingTypeController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill all fields',
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

    setState(() => _isLoading = true);
    final newItem = GeneralItem(
      id: item?.id ?? const Uuid().v4(),
      name: _itemNameController.text.trim(),
      packagingType: _packagingTypeController.text.trim(),
      createdBy: _authService.currentUser!.uid,
      createdAt: Timestamp.now(),
    );

    try {
      if (item == null) {
        await _firestoreService.addGeneralItem(newItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item added successfully',
                style: AppTypography.bodyText,
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        await _firestoreService.updateGeneralItem(newItem.id, newItem.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Item updated successfully',
                style: AppTypography.bodyText,
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: AppTypography.bodyText),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editRequest(ItemRequest request) async {
    final quantityController = TextEditingController(
      text: request.quantity.toString(),
    );
    final result = await showDialog<Map<String, dynamic>>(
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
                      'Edit Request',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            labelStyle: AppTypography.bodyText.copyWith(
                              color: Colors.grey,
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
                              ),
                            ),
                          ),
                          style: AppTypography.bodyText,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: AppTypography.bodyText.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                final qty =
                                    int.tryParse(quantityController.text) ?? 0;
                                if (qty <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Quantity must be greater than zero',
                                        style: AppTypography.bodyText,
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context, {'quantity': qty});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
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
                                  'Update',
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
                ],
              ),
            ),
          ),
    );

    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
        final updatedRequest = ItemRequest(
          id: request.id,
          itemId: request.itemId,
          itemName: request.itemName,
          quantity: result['quantity'],
          requesterId: request.requesterId,
          status: request.status,
          createdAt: request.createdAt,
          purpose: request.purpose,
          reason: request.reason,
        );
        await _firestoreService.addItemRequest(updatedRequest);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Request updated successfully',
                style: AppTypography.bodyText,
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
              content: Text('Error: $e', style: AppTypography.bodyText),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
    quantityController.dispose();
  }

  Future<void> _deleteItem(String id) async {
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
                    offset: const Offset(0, 2),
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
                      'Confirm Deletion',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Are you sure you want to delete this item? This action cannot be undone.',
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
                              'Delete',
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

    setState(() => _isLoading = true);
    try {
      await _firestoreService.deleteGeneralItem(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item deleted successfully',
              style: AppTypography.bodyText,
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
            content: Text('Error: $e', style: AppTypography.bodyText),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRequest(String id) async {
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
                    offset: const Offset(0, 2),
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
                      'Confirm Deletion',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Are you sure you want to delete this request?',
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
                              'Delete',
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

    setState(() => _isLoading = true);
    try {
      await _firestoreService.deleteItemRequest(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request deleted successfully',
              style: AppTypography.bodyText,
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
            content: Text('Error: $e', style: AppTypography.bodyText),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitRequests() async {
    if (_selectedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select at least one item',
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

    bool hasInvalidQuantity = false;
    _selectedItems.forEach((key, value) {
      if (value <= 0) hasInvalidQuantity = true;
    });

    if (hasInvalidQuantity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantity must be greater than zero',
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

    setState(() => _isLoading = true);
    try {
      for (var entry in _selectedItems.entries) {
        final itemId = entry.key;
        final quantity = entry.value;
        final item = await _firestoreService.getGeneralItemById(itemId);
        if (item != null) {
          final request = ItemRequest(
            id: const Uuid().v4(),
            itemId: itemId,
            itemName: item.name,
            quantity: quantity,
            requesterId: _authService.currentUser!.uid,
            status: 'pending',
            createdAt: DateTime.now(),
          );
          await _firestoreService.addItemRequest(request);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Requests submitted successfully',
              style: AppTypography.bodyText,
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      _resetSelections();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: AppTypography.bodyText),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isAddingItem = false;
      _isEditingItem = false;
      _editingItemId = null;
      _itemNameController.clear();
      _packagingTypeController.clear();
    });
  }

  void _resetSelections() {
    setState(() {
      _selectedItems.clear();
      _quantityControllers.forEach((key, controller) => controller.dispose());
      _quantityControllers.clear();
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _packagingTypeController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _quantityControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('General Items', style: AppTypography.heading1),
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
        actions: [
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        setState(() {
                          _isAddingItem = true;
                          _isEditingItem = false;
                          _editingItemId = null;
                          _itemNameController.clear();
                          _packagingTypeController.clear();
                        });
                      },
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder:
                        (widget) => SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(child: widget),
                        ),
                    children: [
                      if (_role == 'admin') _buildAdminControls(),
                      _buildSearchAndSortBar(),
                      if (_isAddingItem && _role == 'admin')
                        _buildAddItemForm(),
                      if (_role != 'admin') _buildUserRequests(),
                      _buildItemList(),
                      if (_role != 'admin') _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminControls() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: AnimationLimiter(
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
                    'Generate Report',
                    style: AppTypography.heading2.copyWith(
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _pickDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _dateRange == null
                                  ? 'Select Date Range'
                                  : '${_dateRange!.start.toString().split(' ')[0]} - ${_dateRange!.end.toString().split(' ')[0]}',
                              style: AppTypography.bodyText.copyWith(
                                color: const Color(0xFF4CAF50),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _selectUser,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _selectedUserName ?? 'All Users',
                              style: AppTypography.bodyText.copyWith(
                                color: const Color(0xFF4CAF50),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _isLoading ? null : _generateReport,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                      child: Text(
                        'Export to PDF',
                        textAlign: TextAlign.center,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: AppTypography.bodyText.copyWith(
                    color: Colors.grey[600],
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4CAF50),
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF4CAF50),
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                ),
                style: AppTypography.bodyText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddItemForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
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
                padding: const EdgeInsets.all(16.0),
                child: AnimationLimiter(
                  child: Column(
                    children: AnimationConfiguration.toStaggeredList(
                      duration: const Duration(milliseconds: 375),
                      childAnimationBuilder:
                          (widget) => SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(child: widget),
                          ),
                      children: [
                        TextField(
                          controller: _itemNameController,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            labelStyle: AppTypography.bodyText.copyWith(
                              color: Colors.grey,
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
                              ),
                            ),
                            errorText:
                                _itemNameController.text.trim().isEmpty &&
                                        _isAddingItem
                                    ? 'Item name is required'
                                    : null,
                          ),
                          style: AppTypography.bodyText,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value:
                              _packagingTypeController.text.isEmpty
                                  ? null
                                  : _packagingTypeController.text,
                          decoration: InputDecoration(
                            labelText: 'Packaging Type',
                            labelStyle: AppTypography.bodyText.copyWith(
                              color: Colors.grey,
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
                              ),
                            ),
                            errorText:
                                _packagingTypeController.text.trim().isEmpty &&
                                        _isAddingItem
                                    ? 'Packaging type is required'
                                    : null,
                          ),
                          style: AppTypography.bodyText,
                          items:
                              _packagingTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        type,
                                        style: AppTypography.bodyText,
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              _isLoading
                                  ? null
                                  : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _packagingTypeController.text = value;
                                      });
                                    }
                                  },
                          isExpanded: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _isLoading ? null : _resetForm,
                              child: Text(
                                'Cancel',
                                style: AppTypography.bodyText.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap:
                                  _isLoading
                                      ? null
                                      : () => _addOrEditItem(
                                        item:
                                            _isEditingItem
                                                ? GeneralItem(
                                                  id: _editingItemId!,
                                                  name:
                                                      _itemNameController.text
                                                          .trim(),
                                                  packagingType:
                                                      _packagingTypeController
                                                          .text
                                                          .trim(),
                                                  createdBy:
                                                      _authService
                                                          .currentUser!
                                                          .uid,
                                                  createdAt: Timestamp.now(),
                                                )
                                                : null,
                                      ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF66BB6A),
                                    ],
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
                                  _isEditingItem ? 'Update Item' : 'Add Item',
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
          ),
        ),
      ),
    );
  }

  Widget _buildUserRequests() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: StreamBuilder<List<ItemRequest>>(
              stream: _firestoreService.streamFilteredItemRequests(
                requesterId: _authService.currentUser!.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading requests',
                      style: AppTypography.bodyText.copyWith(color: Colors.red),
                    ),
                  );
                }
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Center(
                    child: Text(
                      'No requests found',
                      style: AppTypography.bodyText.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Requests',
                      style: AppTypography.heading2.copyWith(
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  title: Text(
                                    request.itemName,
                                    style: AppTypography.bodyText.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Quantity: ${request.quantity} | Status: ${request.status}',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing:
                                      request.status == 'pending'
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.blue,
                                                ),
                                                onPressed:
                                                    _isLoading
                                                        ? null
                                                        : () => _editRequest(
                                                          request,
                                                        ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    _isLoading
                                                        ? null
                                                        : () => _deleteRequest(
                                                          request.id,
                                                        ),
                                              ),
                                            ],
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: StreamBuilder<List<GeneralItem>>(
              stream: _firestoreService.getAllGeneralItems(),
              builder: (context, itemSnapshot) {
                if (itemSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (itemSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading items',
                      style: AppTypography.bodyText.copyWith(color: Colors.red),
                    ),
                  );
                }
                final items = itemSnapshot.data ?? [];
                final filteredItems =
                    items.where((item) {
                      return item.name.toLowerCase().contains(
                        _searchController.text.toLowerCase(),
                      );
                    }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items found',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<ItemRequest>>(
                  stream: _firestoreService.streamFilteredItemRequests(
                    requesterId: _authService.currentUser!.uid,
                  ),
                  builder: (context, requestSnapshot) {
                    if (requestSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (requestSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading requests',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }
                    final requests = requestSnapshot.data ?? [];
                    final requestedItemIds =
                        requests
                            .where((req) => req.status == 'pending')
                            .map((req) => req.itemId)
                            .toSet();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = _selectedItems.containsKey(item.id);
                        final isRequested = requestedItemIds.contains(item.id);

                        if (isSelected &&
                            !_quantityControllers.containsKey(item.id)) {
                          _quantityControllers[item.id] =
                              TextEditingController();
                        }

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 20.0,
                            child: FadeInAnimation(
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF5F5F5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.1),
                                      child: Text(
                                        item.name[0].toUpperCase(),
                                        style: AppTypography.bodyText.copyWith(
                                          color: const Color(0xFF4CAF50),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      item.name,
                                      style: AppTypography.bodyText.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Packaging: ${item.packagingType}',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    trailing:
                                        _role == 'admin'
                                            ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.blue,
                                                  ),
                                                  onPressed:
                                                      _isLoading
                                                          ? null
                                                          : () {
                                                            setState(() {
                                                              _isAddingItem =
                                                                  true;
                                                              _isEditingItem =
                                                                  true;
                                                              _editingItemId =
                                                                  item.id;
                                                              _itemNameController
                                                                      .text =
                                                                  item.name;
                                                              _packagingTypeController
                                                                      .text =
                                                                  item.packagingType;
                                                            });
                                                          },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed:
                                                      _isLoading
                                                          ? null
                                                          : () => _deleteItem(
                                                            item.id,
                                                          ),
                                                ),
                                              ],
                                            )
                                            : isRequested
                                            ? const Text(
                                              'Requested',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                            : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Checkbox(
                                                  value: isSelected,
                                                  activeColor: const Color(
                                                    0xFF4CAF50,
                                                  ),
                                                  onChanged:
                                                      _isLoading
                                                          ? null
                                                          : (value) {
                                                            setState(() {
                                                              if (value ==
                                                                  true) {
                                                                _selectedItems[item
                                                                        .id] =
                                                                    0;
                                                                _quantityControllers[item
                                                                        .id] =
                                                                    TextEditingController();
                                                              } else {
                                                                _selectedItems
                                                                    .remove(
                                                                      item.id,
                                                                    );
                                                                _quantityControllers[item
                                                                        .id]
                                                                    ?.dispose();
                                                                _quantityControllers
                                                                    .remove(
                                                                      item.id,
                                                                    );
                                                              }
                                                            });
                                                          },
                                                ),
                                                if (isSelected)
                                                  SizedBox(
                                                    width: 80,
                                                    child: TextField(
                                                      controller:
                                                          _quantityControllers[item
                                                              .id],
                                                      enabled: !_isLoading,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ],
                                                      decoration: InputDecoration(
                                                        hintText: 'Qty',
                                                        hintStyle: AppTypography
                                                            .caption
                                                            .copyWith(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                        filled: true,
                                                        fillColor: Colors.white,
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              borderSide:
                                                                  const BorderSide(
                                                                    color: Color(
                                                                      0xFF4CAF50,
                                                                    ),
                                                                  ),
                                                            ),
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 8,
                                                            ),
                                                      ),
                                                      style:
                                                          AppTypography
                                                              .bodyText,
                                                      onChanged: (value) {
                                                        final qty =
                                                            int.tryParse(
                                                              value,
                                                            ) ??
                                                            0;
                                                        setState(() {
                                                          _selectedItems[item
                                                                  .id] =
                                                              qty;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                    onTap:
                                        _role != 'admin' &&
                                                !_isLoading &&
                                                !isRequested
                                            ? () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedItems.remove(
                                                    item.id,
                                                  );
                                                  _quantityControllers[item.id]
                                                      ?.dispose();
                                                  _quantityControllers.remove(
                                                    item.id,
                                                  );
                                                } else {
                                                  _selectedItems[item.id] = 0;
                                                  _quantityControllers[item
                                                          .id] =
                                                      TextEditingController();
                                                }
                                              });
                                            }
                                            : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: GestureDetector(
              onTap:
                  _isLoading || _selectedItems.isEmpty ? null : _submitRequests,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                child: Text(
                  'Submit Requests',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
