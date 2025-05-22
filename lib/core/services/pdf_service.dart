import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/inventory_item.dart';

class PdfService {
  Future<File> generateInventoryReport(
    List<InventoryItem> items,
    String userName,
    DateTimeRange dateRange,
  ) async {
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
                        '\$${items.fold(0, (sum, item) => sum + (item.amount * 100))}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Bill To
                pw.Text(
                  'Report For: $userName',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Date Range: ${dateRange.start.toString().split(' ')[0]} to ${dateRange.end.toString().split(' ')[0]}',
                ),
                pw.SizedBox(height: 20),

                // Table
                pw.Table.fromTextArray(
                  headers: [
                    'ID',
                    'Name',
                    'Amount',
                    'Condition',
                    'Category',
                    'Location',
                  ],
                  data:
                      items
                          .map(
                            (item) => [
                              item.id,
                              item.name,
                              item.amount.toString(),
                              item.condition,
                              item.category,
                              item.location ?? 'N/A',
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
                  '123 Green Lane, Nairobi, Kenya',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Any Questions? support@mizizi.co.ke',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/inventory_report.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
