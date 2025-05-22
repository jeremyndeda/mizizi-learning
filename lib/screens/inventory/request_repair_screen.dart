import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class RequestRepairScreen extends StatelessWidget {
  final InventoryItem item;

  const RequestRepairScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final _descriptionController = TextEditingController();
    final NotificationService _notificationService = NotificationService();

    void _requestRepair() async {
      await _notificationService.sendInventoryNotification(
        item.userId,
        'Repair Requested',
        'A repair has been requested for ${item.name}: ${_descriptionController.text.trim()}',
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repair request sent successfully')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Repair', style: AppTypography.heading2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Requesting repair for: ${item.name}',
              style: AppTypography.bodyText,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              labelText: 'Describe the issue',
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Submit Request', onPressed: _requestRepair),
          ],
        ),
      ),
    );
  }
}
