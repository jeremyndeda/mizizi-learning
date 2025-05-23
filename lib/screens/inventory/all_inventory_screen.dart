import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'request_repair_screen.dart';
import 'issue_dialog.dart';
import 'report_filter_dialog.dart';

class AllInventoryScreen extends StatelessWidget {
  const AllInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();
    final NotificationService notificationService = NotificationService();
    final PdfService pdfService = PdfService();

    return FutureBuilder<String>(
      future: authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('All Inventory', style: AppTypography.heading2),
            ),
            body: const Center(
              child: Text(
                'Only admins can view all inventory items.',
                style: AppTypography.bodyText,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('All Inventory', style: AppTypography.heading2),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder:
                        (context) => ReportFilterDialog(
                          currentUserId: authService.currentUser!.uid,
                        ),
                  );
                  if (result != null) {
                    final file = await pdfService.generateInventoryReport(
                      userId: result['userId'],
                      dateRange: result['dateRange'],
                      specificDate: result['specificDate'],
                      userName: result['userName'],
                    );
                    Share.shareXFiles([
                      XFile(file.path),
                    ], text: 'Inventory Report');
                  }
                },
              ),
            ],
          ),
          body: StreamBuilder<List<InventoryItem>>(
            stream: firestoreService.getAllInventory(),
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
                      if (authService.currentUser?.uid == item.userId) {
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
                      if (authService.currentUser?.uid == item.userId) {
                        await firestoreService.deleteInventoryItem(item.id);
                        await notificationService.sendInventoryNotification(
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
                      if (authService.currentUser?.uid == item.userId &&
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
      },
    );
  }
}
