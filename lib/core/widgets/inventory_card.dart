import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';
import '../models/inventory_item.dart';
import '../services/auth_service.dart';

class InventoryCard extends StatelessWidget {
  final InventoryItem item;
  final String currentUserRole;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIssue;
  final Widget? child;

  const InventoryCard({
    super.key,
    required this.item,
    required this.currentUserRole,
    required this.onEdit,
    required this.onDelete,
    required this.onIssue,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = AuthService().currentUser?.uid == item.userId;
    final canIssue = currentUserRole == 'admin' || currentUserRole == 'care';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      child: Card(
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
              if (item.condition != null)
                Text(
                  'Condition: ${item.condition}',
                  style: AppTypography.bodyText,
                ),
              Text('Category: ${item.category}', style: AppTypography.bodyText),
              if (item.location != null)
                Text(
                  'Location: ${item.location}',
                  style: AppTypography.bodyText,
                ),
              Text(
                'Owner: ${item.userEmail ?? 'Unknown'}',
                style: AppTypography.bodyText,
              ),
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
                        isOwner
                            ? 'Delete'
                            : 'You can only delete your own items',
                  ),
                  if (canIssue && isOwner && item.amount > 0)
                    ElevatedButton(
                      onPressed: onIssue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Issue'),
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
