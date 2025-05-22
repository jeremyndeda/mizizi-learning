// ignore_for_file: unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/typography.dart';
import '../../../core/models/inventory_item.dart';
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
      // Get inventory items for user
      final items =
          await _firestoreService.getUserInventory(widget.userId).first;
      final user = await _firestoreService.getUser(widget.userId);

      // Filter items by selected date range
      final filteredItems =
          items.where((item) {
            if (_dateRange == null) return true;
            return item.createdAt.isAfter(_dateRange!.start) &&
                item.createdAt.isBefore(_dateRange!.end);
          }).toList();

      // Generate PDF file
      final file = await _pdfService.generateInventoryReport(
        filteredItems,
        user?.name ?? user?.email ?? 'User',
        _dateRange ?? DateTimeRange(start: DateTime(2020), end: DateTime.now()),
      );

      // Share the PDF file using share_plus
      await Share.shareXFiles([XFile(file.path)], text: 'Inventory Report');
    } catch (e) {
      // Handle any errors gracefully
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}
