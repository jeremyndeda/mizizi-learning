import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'request_repair_screen.dart';

class UserInventoryScreen extends StatelessWidget {
  const UserInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory', style: AppTypography.heading2),
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: FirestoreService().getUserInventory(userId),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AddEditItemScreen(userId: userId, item: item),
                    ),
                  );
                },
                onDelete: () {
                  FirestoreService().deleteInventoryItem(item.id);
                },
                onRequestRepair: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestRepairScreen(item: item),
                    ),
                  );
                },
                child: Text(
                  'Amount: ${item.amount}',
                  style: AppTypography.bodyText,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditItemScreen(userId: userId),
            ),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
