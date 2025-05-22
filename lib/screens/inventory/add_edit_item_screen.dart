import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class AddEditItemScreen extends StatefulWidget {
  final String userId;
  final InventoryItem? item;

  const AddEditItemScreen({super.key, required this.userId, this.item});

  @override
  _AddEditItemScreenState createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _amountController = TextEditingController();
  String? _condition = 'Good';
  String _category = 'Stationery';
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  static const _categoriesRequiringCondition = [
    'Electronics',
    'Furniture',
    'Kids Toys',
    'Accessories',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId != widget.item!.userId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only edit your own items.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
          Navigator.pop(context);
        });
        return;
      }

      _nameController.text = widget.item!.name;
      _descriptionController.text = widget.item!.description ?? '';
      _locationController.text = widget.item!.location ?? '';
      _amountController.text = widget.item!.amount.toString();
      _condition = widget.item!.condition;
      _category = widget.item!.category;
    } else {
      _amountController.text = '1';
    }
  }

  bool _requiresCondition() {
    return _categoriesRequiringCondition.contains(_category);
  }

  void _saveItem() async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 1;
    final currentUser = _authService.currentUser!;
    final item = InventoryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      condition: _requiresCondition() ? _condition : null,
      category: _category,
      userId: widget.userId,
      userEmail: currentUser.email!, // Explicitly set owner email
      createdAt: DateTime.now(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      amount: amount,
    );

    if (widget.item == null) {
      await _firestoreService.addInventoryItem(item);
      await _notificationService.sendInventoryNotification(
        widget.userId,
        'Item Added',
        'Item ${item.name} (x$amount) has been added to your inventory.',
      );
    } else {
      await _firestoreService.updateInventoryItem(item.id, item.toMap());
      await _notificationService.sendInventoryNotification(
        widget.userId,
        'Item Updated',
        'Item ${item.name} (x$amount) has been updated.',
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add Item' : 'Edit Item',
          style: AppTypography.heading2,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              labelText: 'Item Name',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Description',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _locationController,
              labelText: 'Location',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _amountController,
              labelText: 'Amount',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            if (_requiresCondition()) ...[
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  labelStyle: const TextStyle(color: AppColors.primaryGreen),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items:
                    ['Good', 'Needs Repair', 'Damaged'].map((condition) {
                      return DropdownMenuItem(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                onChanged: (value) => setState(() => _condition = value),
              ),
              const SizedBox(height: 16),
            ],
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: const TextStyle(color: AppColors.primaryGreen),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  [
                    'Stationery',
                    'Sanitary Items',
                    'Electronics',
                    'Furniture',
                    'Kids Toys',
                    'Accessories',
                    'Other',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _category = value!;
                  if (!_requiresCondition()) {
                    _condition = null;
                  }
                });
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: widget.item == null ? 'Add Item' : 'Update Item',
              onPressed: _saveItem,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
