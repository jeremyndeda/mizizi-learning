import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/colors.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notification_service.dart';

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

  List<String> _allEmails = [];

  @override
  void initState() {
    super.initState();
    _loadAllEmails();
  }

  Future<void> _loadAllEmails() async {
    final emails =
        await _firestoreService.getAllUserEmails(); // Ensure implemented
    setState(() {
      _allEmails = emails;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Issue ${widget.item.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity to issue (max ${widget.item.amount})',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                final query = textEditingValue.text.toLowerCase();
                return _allEmails.where(
                  (email) => email.toLowerCase().contains(query),
                );
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                _borrowerController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Issued to (email)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                );
              },
              onSelected: (String selection) {
                _borrowerController.text = selection;
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
                            title: Text(option),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
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

            final newAmount = widget.item.amount - quantity;
            await _firestoreService.updateInventoryItem(widget.item.id, {
              'amount': newAmount,
            });

            final newItem = InventoryItem(
              id: const Uuid().v4(),
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
