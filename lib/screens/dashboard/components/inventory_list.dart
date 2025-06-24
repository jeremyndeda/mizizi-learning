import 'package:flutter/material.dart';
import '../../../core/constants/typography.dart';
import '../../../core/models/inventory_item.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/inventory_card.dart';
import '../../../core/widgets/filter_chip.dart';
import '../../inventory/add_edit_item_screen.dart';
import '../../inventory/issue_dialog.dart';

class InventoryList extends StatefulWidget {
  final String userId;

  const InventoryList({super.key, required this.userId});

  @override
  _InventoryListState createState() => _InventoryListState();
}

class _InventoryListState extends State<InventoryList> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  String? _selectedUserFilter;
  String? _selectedCategoryFilter;
  String? _selectedConditionFilter;

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    String itemName,
    String userId,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Confirm Deletion',
              style: AppTypography.heading2,
            ),
            content: Text(
              'Are you sure you want to delete "$itemName"? This action cannot be undone.',
              style: AppTypography.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: AppTypography.buttonText),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      await _firestoreService.deleteInventoryItem(itemId);
      await _notificationService.sendInventoryNotification(
        userId,
        'Item Deleted',
        'Item $itemName has been deleted.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"$itemName" deleted successfully',
              style: AppTypography.bodyText,
            ),
            backgroundColor: const Color(0xFF4CAF50), // Green
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
    return FutureBuilder<String>(
      future: _authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final role = snapshot.data ?? 'user';
        Stream<List<InventoryItem>> inventoryStream =
            role == 'admin'
                ? _firestoreService.getAllInventory()
                : _firestoreService.getUserInventory(widget.userId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inventory Overview', style: AppTypography.heading2),
            const SizedBox(height: 12),
            _buildFilterChips(role),
            const SizedBox(height: 16),
            StreamBuilder<List<InventoryItem>>(
              stream: inventoryStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var items = snapshot.data!;
                if (_selectedUserFilter != null) {
                  items =
                      items
                          .where((item) => item.userId == _selectedUserFilter)
                          .toList();
                }
                if (_selectedCategoryFilter != null) {
                  items =
                      items
                          .where(
                            (item) => item.category == _selectedCategoryFilter,
                          )
                          .toList();
                }
                if (_selectedConditionFilter != null) {
                  items =
                      items
                          .where(
                            (item) =>
                                item.condition == _selectedConditionFilter,
                          )
                          .toList();
                }

                final totalItems = items.length;
                final start = _currentPage * _itemsPerPage;
                final end = (_currentPage + 1) * _itemsPerPage;
                final pagedItems = items.sublist(
                  start,
                  end > totalItems ? totalItems : end,
                );

                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AddEditItemScreen(userId: widget.userId),
                          ),
                        );
                      },
                      child: const Text('Add New Item'),
                    ),
                    const SizedBox(height: 8),
                    ...pagedItems.map(
                      (item) => FutureBuilder<UserModel?>(
                        future: _firestoreService.getUser(item.userId),
                        builder: (context, userSnapshot) {
                          String ownerName = 'Unknown';
                          if (userSnapshot.hasData &&
                              userSnapshot.data != null) {
                            ownerName =
                                userSnapshot.data!.name ??
                                userSnapshot.data!.email;
                          }
                          final isOwner =
                              _authService.currentUser?.uid == item.userId;
                          return InventoryCard(
                            item: item,
                            currentUserRole: role,
                            ownerName: ownerName,
                            onEdit:
                                isOwner
                                    ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AddEditItemScreen(
                                              userId: widget.userId,
                                              item: item,
                                            ),
                                      ),
                                    )
                                    : null, // Hide edit button if not owner
                            onDelete:
                                isOwner
                                    ? () => _confirmDelete(
                                      context,
                                      item.id,
                                      item.name,
                                      widget.userId,
                                    )
                                    : null, // Hide delete button if not owner
                            onIssue: () => _handleIssue(item, role),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed:
                              _currentPage > 0
                                  ? () => setState(() => _currentPage--)
                                  : null,
                          child: const Text('Previous'),
                        ),
                        Text(
                          'Page ${_currentPage + 1} of ${(totalItems / _itemsPerPage).ceil()}',
                        ),
                        TextButton(
                          onPressed:
                              end < totalItems
                                  ? () => setState(() => _currentPage++)
                                  : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(String role) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (role == 'admin') ...[
            CustomFilterChip(
              label: 'All Users',
              isSelected: _selectedUserFilter == null,
              onSelected: () {
                setState(() {
                  _selectedUserFilter = null;
                  _currentPage = 0;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          CustomFilterChip(
            label: 'My Items',
            isSelected: _selectedUserFilter == widget.userId,
            onSelected: () {
              setState(() {
                _selectedUserFilter = widget.userId;
                _currentPage = 0;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildCategoryChip('Stationery'),
          _buildCategoryChip('Sanitary Items'),
          _buildCategoryChip('Electronics'),
          _buildCategoryChip('Furniture'),
          _buildCategoryChip('Kids Toys'),
          _buildCategoryChip('Accessories'),
          _buildCategoryChip('Food Items'),
          _buildConditionChip('Good'),
          _buildConditionChip('Needs Repair'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomFilterChip(
        label: category,
        isSelected: _selectedCategoryFilter == category,
        onSelected: () {
          setState(() {
            _selectedCategoryFilter = category;
            _currentPage = 0;
          });
        },
      ),
    );
  }

  Widget _buildConditionChip(String condition) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomFilterChip(
        label: condition,
        isSelected: _selectedConditionFilter == condition,
        onSelected: () {
          setState(() {
            _selectedConditionFilter = condition;
            _currentPage = 0;
          });
        },
      ),
    );
  }

  void _handleIssue(InventoryItem item, String role) {
    if ((role == 'admin' || role == 'care') &&
        _authService.currentUser?.uid == item.userId &&
        item.amount > 0) {
      showDialog(
        context: context,
        builder: (context) => IssueDialog(item: item),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only issue your own items with available amount',
          ),
        ),
      );
    }
  }
}
