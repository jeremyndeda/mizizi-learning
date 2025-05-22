import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/inventory_item.dart';
import 'firestore_service.dart';

class PdfService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<File> generateInventoryReport({
    String? userId,
    DateTimeRange? dateRange,
    DateTime? specificDate,
    String? userName,
  }) async {
    // Fetch filtered inventory items
    List<InventoryItem> items;
    String reportTitle = 'Inventory Report';
    String filterDetails = '';

    if (userId != null) {
      items = await _firestoreService.getUserInventory(userId).first;
      filterDetails = 'User: ${userName ?? userId}';
    } else if (dateRange != null) {
      items = await _firestoreService.getInventoryByDateRange(
        dateRange.start,
        dateRange.end,
      );
      filterDetails =
          'Date Range: ${dateRange.start.toString().split(' ')[0]} to ${dateRange.end.toString().split(' ')[0]}';
    } else if (specificDate != null) {
      items = await _firestoreService.getInventoryByDate(specificDate);
      filterDetails = 'Date: ${specificDate.toString().split(' ')[0]}';
    } else {
      items = await _firestoreService.getAllInventory().first;
      filterDetails = 'All Inventory Items';
    }

    // Create PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  color: PdfColors.blue,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'INVENTORY REPORT',
                        style: pw.TextStyle(
                          fontSize: 20,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Total Items: ${items.length}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Filter Details
                pw.Text(filterDetails, style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),

                // Table
                pw.TableHelper.fromTextArray(
                  headers: [
                    'ID',
                    'Name',
                    'Amount',
                    'Condition',
                    'Category',
                    'Owner',
                    'Date Added',
                  ],
                  data:
                      items
                          .map(
                            (item) => [
                              item.id.substring(
                                0,
                                8,
                              ), // Shorten ID for readability
                              item.name,
                              item.amount.toString(),
                              item.condition ?? 'N/A',
                              item.category,
                              item.userEmail ?? 'Unknown',
                              item.createdAt.toString().split(' ')[0],
                            ],
                          )
                          .toList(),
                  border: null,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellHeight: 30,
                ),
                pw.SizedBox(height: 20),

                // Footer
                pw.Divider(),
                pw.Text(
                  'Mizizi Learning Hub',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Lavington, Nairobi, Kenya',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Generated on: ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Any Questions? support@mizizilearning.com',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
      ),
    );

    // Save PDF to temporary directory
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/inventory_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
