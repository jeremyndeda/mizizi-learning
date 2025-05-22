import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'request_repair_screen.dart';
import 'issue_dialog.dart';

class AllInventoryScreen extends StatelessWidget {
  const AllInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final NotificationService _notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Inventory', style: AppTypography.heading2),
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: _firestoreService.getAllInventory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InventoryCard(
                item: item,
                onEdit: () {
                  if (AuthService().currentUser?.uid == item.userId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddEditItemScreen(
                              userId: item.userId,
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
                  if (AuthService().currentUser?.uid == item.userId) {
                    await _firestoreService.deleteInventoryItem(item.id);
                    await _notificationService.sendInventoryNotification(
                      item.userId,
                      'Item Deleted',
                      'Item ${item.name} has been deleted.',
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You can only delete your own items'),
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
                  if (AuthService().currentUser?.uid == item.userId &&
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
    );
  }
}
