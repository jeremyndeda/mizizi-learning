import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'request_repair_screen.dart';

class AllInventoryScreen extends StatelessWidget {
  const AllInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Inventory', style: AppTypography.heading2),
      ),
      body: StreamBuilder<List<InventoryItem>>(
        stream: FirestoreService().getAllInventory(),
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
                          (_) => AddEditItemScreen(
                            userId: item.userId,
                            item: item,
                          ),
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
              );
            },
          );
        },
      ),
    );
  }
}
