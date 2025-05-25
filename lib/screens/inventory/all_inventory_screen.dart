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
import 'issue_dialog.dart';
import 'report_filter_dialog.dart';

class AllInventoryScreen extends StatefulWidget {
  const AllInventoryScreen({super.key});

  @override
  State<AllInventoryScreen> createState() => _AllInventoryScreenState();
}

class _AllInventoryScreenState extends State<AllInventoryScreen> {
  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();
  final NotificationService notificationService = NotificationService();
  final PdfService pdfService = PdfService();

  int _currentPage = 0;
  final int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data ?? 'user';
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('All Inventory', style: AppTypography.heading2),
            ),
            body: const Center(
              child: Text('Only admins can view all inventory items.'),
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
              final totalItems = items.length;
              final start = _currentPage * _itemsPerPage;
              final end = (_currentPage + 1) * _itemsPerPage;
              final pagedItems = items.sublist(
                start,
                end > totalItems ? totalItems : end,
              );

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: pagedItems.length,
                      itemBuilder: (context, index) {
                        final item = pagedItems[index];
                        return InventoryCard(
                          item: item,
                          currentUserRole: role,
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
                                  content: Text(
                                    'You can only edit your own items',
                                  ),
                                ),
                              );
                            }
                          },
                          onDelete: () async {
                            if (authService.currentUser?.uid == item.userId) {
                              await firestoreService.deleteInventoryItem(
                                item.id,
                              );
                              await notificationService
                                  .sendInventoryNotification(
                                    item.userId,
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
                          onIssue: () {
                            if ((role == 'admin' || role == 'care') &&
                                authService.currentUser?.uid == item.userId &&
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
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
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
