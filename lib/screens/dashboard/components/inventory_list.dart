import 'package:flutter/material.dart';
import '../../../core/constants/typography.dart';
import '../../../core/models/inventory_item.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/inventory_card.dart';
import '../../../core/widgets/filter_chip.dart';
import '../../inventory/add_edit_item_screen.dart';
import '../../inventory/issue_dialog.dart';
import '../../inventory/request_repair_screen.dart';

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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (role == 'admin') ...[
                    CustomFilterChip(
                      label: 'All Users',
                      isSelected: _selectedUserFilter == null,
                      onSelected:
                          () => setState(() => _selectedUserFilter = null),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CustomFilterChip(
                    label: 'My Items',
                    isSelected: _selectedUserFilter == widget.userId,
                    onSelected:
                        () =>
                            setState(() => _selectedUserFilter = widget.userId),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Stationery',
                    isSelected: _selectedCategoryFilter == 'Stationery',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Stationery',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Sanitary Items',
                    isSelected: _selectedCategoryFilter == 'Sanitary Items',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Sanitary Items',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Electronics',
                    isSelected: _selectedCategoryFilter == 'Electronics',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Electronics',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Furniture',
                    isSelected: _selectedCategoryFilter == 'Furniture',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Furniture',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Kids Toys',
                    isSelected: _selectedCategoryFilter == 'Kids Toys',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Kids Toys',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Accessories',
                    isSelected: _selectedCategoryFilter == 'Accessories',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Accessories',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Food Items',
                    isSelected: _selectedCategoryFilter == 'Food Items',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Food Items',
                        ),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Good',
                    isSelected: _selectedConditionFilter == 'Good',
                    onSelected:
                        () => setState(() => _selectedConditionFilter = 'Good'),
                  ),
                  const SizedBox(width: 8),
                  CustomFilterChip(
                    label: 'Needs Repair',
                    isSelected: _selectedConditionFilter == 'Needs Repair',
                    onSelected:
                        () => setState(
                          () => _selectedCategoryFilter = 'Needs Repair',
                        ),
                  ),
                ],
              ),
            ),
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

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      AddEditItemScreen(userId: widget.userId),
                            ),
                          );
                        },
                        child: const Text('Add New Item'),
                      );
                    }

                    final item = items[index - 1];
                    return InventoryCard(
                      item: item,
                      onEdit: () {
                        if (_authService.currentUser?.uid == item.userId) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AddEditItemScreen(
                                    userId: widget.userId,
                                    item: item,
                                  ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You can only edit your own items'),
                            ),
                          );
                        }
                      },
                      onDelete: () async {
                        if (_authService.currentUser?.uid == item.userId) {
                          await _firestoreService.deleteInventoryItem(item.id);
                          await _notificationService.sendInventoryNotification(
                            widget.userId,
                            'Item Deleted',
                            'Item ${item.name} has been deleted.',
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You can only delete your own items',
                              ),
                            ),
                          );
                        }
                      },
                      onRequestRepair: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestRepairScreen(item: item),
                          ),
                        );
                      },
                      onIssue: () {
                        if (_authService.currentUser?.uid == item.userId &&
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
                      },
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
