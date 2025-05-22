import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/colors.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_text_field.dart';

class IssueDialog extends StatefulWidget {
  final InventoryItem item;

  const IssueDialog({super.key, required this.item});

  @override
  _IssueDialogState createState() => _IssueDialogState();
}

class _IssueDialogState extends State<IssueDialog> {
  final _quantityController = TextEditingController();
  final _borrowerController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Issue ${widget.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _quantityController,
            labelText: 'Quantity to issue (max ${widget.item.amount})',
            keyboardType: TextInputType.number,
          ),
          CustomTextField(
            controller: _borrowerController,
            labelText: 'Issued to (email)',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
            final borrowerEmail = _borrowerController.text.trim();

            // Validate recipient
            final recipient = await _firestoreService.getUserByEmail(
              borrowerEmail,
            );
            if (recipient == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('User with email $borrowerEmail not found'),
                  backgroundColor: AppColors.errorRed,
                ),
              );
              return;
            }

            // Validate quantity
            if (quantity <= 0 || quantity > widget.item.amount) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invalid quantity. Must be between 1 and ${widget.item.amount}',
                  ),
                  backgroundColor: AppColors.errorRed,
                ),
              );
              return;
            }

            // Update issuer's inventory
            final newAmount = widget.item.amount - quantity;
            await _firestoreService.updateInventoryItem(widget.item.id, {
              'amount': newAmount,
            });

            // Create recipient's inventory entry
            final newItem = InventoryItem(
              id: const Uuid().v4(), // Unique ID for new entry
              name: widget.item.name,
              condition: widget.item.condition,
              category: widget.item.category,
              userId: recipient.uid,
              userEmail: recipient.email,
              createdAt: DateTime.now(),
              description: widget.item.description,
              location: 'Received from ${_authService.currentUser!.email}',
              amount: quantity,
            );
            await _firestoreService.addInventoryItem(newItem);

            // Notify both issuer and recipient
            await _notificationService.sendInventoryNotification(
              widget.item.userId,
              'Item Issued',
              'You issued $quantity of ${widget.item.name} to $borrowerEmail.',
            );
            await _notificationService.sendInventoryNotification(
              recipient.uid,
              'Item Received',
              'You received $quantity of ${widget.item.name} from ${_authService.currentUser!.email}.',
            );

            // Show success message
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Issued $quantity of ${widget.item.name} to $borrowerEmail',
                ),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          },
          child: const Text('Issue'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _borrowerController.dispose();
    super.dispose();
  }
}
