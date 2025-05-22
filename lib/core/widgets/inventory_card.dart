import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/inventory_item.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRequestRepair;
  final Widget? child;

  const InventoryCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onRequestRepair,
    this.child,
  });

  void _issueItem(BuildContext context) async {
    final TextEditingController issueController = TextEditingController();
    final FirestoreService firestoreService = FirestoreService();
    final NotificationService notificationService = NotificationService();
    final currentUserId = AuthService().currentUser?.uid;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Issue Item'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Amount: ${item.amount}'),
                TextField(
                  controller: issueController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Issue',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final quantityToIssue =
                      int.tryParse(issueController.text) ?? 0;
                  if (quantityToIssue <= 0 || quantityToIssue > item.amount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid quantity.'),
                        backgroundColor: AppColors.errorRed,
                      ),
                    );
                    return;
                  }

                  final newAmount = item.amount - quantityToIssue;
                  if (newAmount <= 0) {
                    // Delete the item if amount reaches 0
                    await firestoreService.deleteInventoryItem(item.id);
                    await notificationService.sendInventoryNotification(
                      currentUserId!,
                      'Item Issued and Removed',
                      'Item ${item.name} has been fully issued and removed from your inventory.',
                    );
                  } else {
                    // Update the item with the new amount
                    final updatedItem = InventoryItem(
                      id: item.id,
                      name: item.name,
                      condition: item.condition,
                      category: item.category,
                      userId: item.userId,
                      userEmail: item.userEmail,
                      createdAt: item.createdAt,
                      description: item.description,
                      location: item.location,
                      amount: newAmount,
                    );
                    await firestoreService.updateInventoryItem(
                      item.id,
                      updatedItem.toMap(),
                    );
                    await notificationService.sendInventoryNotification(
                      currentUserId!,
                      'Item Issued',
                      'Issued $quantityToIssue of ${item.name}. Remaining: $newAmount.',
                    );
                  }

                  Navigator.pop(dialogContext);
                },
                child: const Text('Issue'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const List<String> nonRepairableCategories = [
      'Kids Toys',
      'Sanitary Items',
      'Stationery',
    ];
    final currentUserId = AuthService().currentUser?.uid;
    final isOwner = currentUserId == item.userId;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: AppTypography.heading2),
            const SizedBox(height: 8),
            Text('Amount: ${item.amount}', style: AppTypography.bodyText),
            Text('Condition: ${item.condition}', style: AppTypography.bodyText),
            Text('Category: ${item.category}', style: AppTypography.bodyText),
            if (item.location != null)
              Text('Location: ${item.location}', style: AppTypography.bodyText),
            if (child != null) ...[const SizedBox(height: 8), child!],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primaryGreen),
                  onPressed: isOwner ? onEdit : null,
                  tooltip:
                      isOwner ? 'Edit' : 'You can only edit your own items',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.errorRed),
                  onPressed: isOwner ? onDelete : null,
                  tooltip:
                      isOwner ? 'Delete' : 'You can only delete your own items',
                ),
                if (isOwner) // Show "Issue Item" button only for the owner
                  ElevatedButton(
                    onPressed: () => _issueItem(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Issue Item'),
                  ),
                if (!nonRepairableCategories.contains(item.category) &&
                    !isOwner)
                  ElevatedButton(
                    onPressed: onRequestRepair,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryGreen,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Request/Repair'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
