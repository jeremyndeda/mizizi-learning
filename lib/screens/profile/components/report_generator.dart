import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/typography.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/widgets/custom_button.dart';

class ReportGenerator extends StatefulWidget {
  final String userId;

  const ReportGenerator({super.key, required this.userId});

  @override
  _ReportGeneratorState createState() => _ReportGeneratorState();
}

class _ReportGeneratorState extends State<ReportGenerator> {
  DateTimeRange? _dateRange;
  final FirestoreService _firestoreService = FirestoreService();
  final PdfService _pdfService = PdfService();

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _generateReport() async {
    try {
      final user = await _firestoreService.getUser(widget.userId);
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      final inventoryItems =
          await _firestoreService.getUserInventory(widget.userId).first;
      if (inventoryItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No inventory items found for this user'),
          ),
        );
        return;
      }

      final allRequests = await _firestoreService.getAllItemRequests().first;
      final userRequests =
          allRequests
              .where((request) => request.requesterId == widget.userId)
              .toList();

      final filteredInventoryItems =
          inventoryItems.where((item) {
            if (_dateRange == null) return true;
            return item.createdAt.isAfter(_dateRange!.start) &&
                item.createdAt.isBefore(_dateRange!.end);
          }).toList();

      final filteredRequests =
          (await Future.wait(
            userRequests.map((request) async {
              final item = await _firestoreService.getItemById(request.itemId);
              return request.createdAt.isAfter(
                        _dateRange?.start ?? DateTime(2020),
                      ) &&
                      request.createdAt.isBefore(
                        _dateRange?.end ?? DateTime.now(),
                      )
                  ? {
                    'type': 'Request',
                    'itemName': item?.name ?? 'Unknown',
                    'amount': request.quantity.toString(),
                    'category': item?.category ?? 'N/A',
                    'condition': 'N/A',
                    'user': user.email,
                    'status': request.status,
                    'purpose': request.purpose ?? 'N/A',
                    'reason': request.reason ?? 'N/A',
                    'createdAt': request.createdAt,
                  }
                  : null;
            }),
          )).whereType<Map<String, dynamic>>().toList();

      final allItems = [
        ...filteredInventoryItems.map(
          (item) => {
            'type': 'Inventory',
            'itemName': item.name,
            'amount': item.amount.toString(),
            'category': item.category,
            'condition': item.condition ?? 'N/A',
            'user': item.userEmail ?? 'Unknown',
            'status': 'N/A',
            'purpose': 'N/A',
            'reason': 'N/A',
            'createdAt': item.createdAt,
          },
        ),
        ...filteredRequests,
      ];

      if (allItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No items found for the selected date range'),
          ),
        );
        return;
      }

      final file = await _pdfService.generateInventoryReport(
        userId: widget.userId,
        userName: user.name ?? 'Unknown User',
        dateRange:
            _dateRange == null ? null : [_dateRange!.start, _dateRange!.end],
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Inventory and Requests Report for ${user.name ?? 'Unknown User'}',
      );
    } catch (e) {
      if (e is FileSystemException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create PDF file')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // Ensures full width if in Column
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generate Report', style: AppTypography.heading2),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickDateRange,
                child: Text(
                  _dateRange == null
                      ? 'Select Date Range'
                      : '${_dateRange!.start.toString().split(' ')[0]} to ${_dateRange!.end.toString().split(' ')[0]}',
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(text: 'Export to PDF', onPressed: _generateReport),
            ],
          ),
        ),
      ),
    );
  }
}
