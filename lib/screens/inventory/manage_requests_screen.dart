import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/models/item_request.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class ManageRequestsScreen extends StatelessWidget {
  const ManageRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final NotificationService notificationService = NotificationService();
    final AuthService authService = AuthService();
    final PdfService pdfService = PdfService();
    final Logger logger = Logger('ManageRequestsScreen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests', style: AppTypography.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate All Requests PDF',
            onPressed: () async {
              try {
                final allRequests =
                    await firestoreService.getAllItemRequests().first;

                final file = await pdfService.generateItemRequestsReport(
                  allRequests,
                );

                await Share.shareXFiles([
                  XFile(file.path),
                ], text: 'All Item Requests Report');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate PDF: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ItemRequest>>(
        stream: firestoreService.getAllItemRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No requests found'));
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder(
                future: firestoreService.getUser(request.requesterId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError) {
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Error loading user data'),
                      ),
                    );
                  }

                  final requesterEmail =
                      userSnapshot.data?.email ?? 'Unknown User';

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item: ${request.itemName}',
                            style: AppTypography.bodyText,
                          ),
                          Text(
                            'Quantity: ${request.quantity}',
                            style: AppTypography.bodyText,
                          ),
                          Text(
                            'Requester: $requesterEmail',
                            style: AppTypography.bodyText,
                          ),
                          Text(
                            'Status: ${request.status}',
                            style: AppTypography.bodyText,
                          ),
                          if (request.purpose != null)
                            Text(
                              'Purpose: ${request.purpose}',
                              style: AppTypography.bodyText,
                            ),
                          if (request.reason != null)
                            Text(
                              'Reason: ${request.reason}',
                              style: AppTypography.bodyText,
                            ),
                          if (request.status.toLowerCase() == 'pending') ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Approve',
                                    onPressed: () async {
                                      logger.info(
                                        'Approving request ID: ${request.id}',
                                      );
                                      try {
                                        final item = await firestoreService
                                            .getItemByName(request.itemName);

                                        if (item != null) {
                                          if (item.amount < request.quantity) {
                                            logger.warning(
                                              'Insufficient quantity: ${item.amount} available, ${request.quantity} requested',
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Insufficient quantity available',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await firestoreService
                                              .updateInventoryItem(item.id, {
                                                'amount':
                                                    item.amount -
                                                    request.quantity,
                                              });

                                          final newItem = InventoryItem(
                                            id: const Uuid().v4(),
                                            name: item.name,
                                            condition: item.condition,
                                            category: item.category,
                                            userId: request.requesterId,
                                            userEmail: requesterEmail,
                                            createdAt: DateTime.now(),
                                            description: item.description,
                                            location: item.location,
                                            amount: request.quantity,
                                          );
                                          await firestoreService
                                              .addInventoryItem(newItem);

                                          await firestoreService
                                              .updateItemRequestStatus(
                                                request.id,
                                                'approved',
                                                itemId: item.id,
                                              );
                                        } else {
                                          final confirm = await showDialog<
                                            bool
                                          >(
                                            context: context,
                                            builder:
                                                (context) => AlertDialog(
                                                  title: const Text(
                                                    'Item Not Found',
                                                  ),
                                                  content: Text(
                                                    'The item "${request.itemName}" does not exist in inventory.\n'
                                                    'Would you like to create it and assign it to the requester?',
                                                    style:
                                                        AppTypography.bodyText,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    CustomButton(
                                                      text: 'Create Item',
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                          );

                                          if (confirm != true) return;

                                          final newItem = InventoryItem(
                                            id: const Uuid().v4(),
                                            name: request.itemName,
                                            condition: 'Good',
                                            category: 'Other',
                                            userId: request.requesterId,
                                            userEmail: requesterEmail,
                                            createdAt: DateTime.now(),
                                            description:
                                                request.purpose ??
                                                'No description provided',
                                            location: 'Unknown',
                                            amount: request.quantity,
                                          );
                                          await firestoreService
                                              .addInventoryItem(newItem);

                                          await firestoreService
                                              .updateItemRequestStatus(
                                                request.id,
                                                'approved',
                                                itemId: null,
                                              );
                                        }

                                        await notificationService
                                            .sendInventoryNotification(
                                              request.requesterId,
                                              'Request Approved',
                                              'Your request for ${request.quantity} of ${request.itemName} has been approved.',
                                            );
                                      } catch (e) {
                                        logger.severe(
                                          'Error during approval process: $e',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to approve request: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Reject',
                                    onPressed: () async {
                                      final reasonController =
                                          TextEditingController();
                                      final result = await showDialog<String>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Reject Request',
                                              ),
                                              content: CustomTextField(
                                                controller: reasonController,
                                                labelText:
                                                    'Reason for Rejection',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                CustomButton(
                                                  text: 'Submit',
                                                  onPressed: () {
                                                    if (reasonController.text
                                                        .trim()
                                                        .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Please provide a reason',
                                                          ),
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    Navigator.pop(
                                                      context,
                                                      reasonController.text
                                                          .trim(),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                      );
                                      if (result != null) {
                                        await firestoreService
                                            .updateItemRequestStatus(
                                              request.id,
                                              'rejected',
                                              reason: result,
                                            );
                                        await notificationService
                                            .sendInventoryNotification(
                                              request.requesterId,
                                              'Request Rejected',
                                              'Your request for ${request.quantity} of ${request.itemName} was rejected: $result',
                                            );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
