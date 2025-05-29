import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/inventory_item.dart';
import '../models/item_request.dart';
import 'firestore_service.dart';

class PdfService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Generates a combined Inventory and Item Requests report PDF
  /// Supports filtering by userId, specificDate, or dateRange.
  Future<File> generateInventoryReport({
    String? userId,
    String? userName,
    DateTime? specificDate,
    List<DateTime>? dateRange,
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Fetch inventory and all requests
    final inventoryItems =
        userId != null
            ? await _firestoreService.getUserInventory(userId).first
            : await _firestoreService.getAllInventory().first;
    final allRequests = await _firestoreService.getAllItemRequests().first;

    // Filter inventory by date if needed
    List<InventoryItem> filteredInventoryItems = inventoryItems;
    if (specificDate != null) {
      final startUtc =
          DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day,
          ).toUtc();
      final endUtc = startUtc.add(const Duration(days: 1));
      filteredInventoryItems =
          inventoryItems
              .where(
                (item) =>
                    item.createdAt.isAfter(startUtc) &&
                    item.createdAt.isBefore(endUtc),
              )
              .toList();
    } else if (dateRange != null && dateRange.length == 2) {
      final startUtc = dateRange[0].toUtc();
      final endUtc = dateRange[1].add(const Duration(days: 1)).toUtc();
      filteredInventoryItems =
          inventoryItems
              .where(
                (item) =>
                    item.createdAt.isAfter(startUtc) &&
                    item.createdAt.isBefore(endUtc),
              )
              .toList();
    }

    // Filter requests by date and userId if needed
    List<ItemRequest> filteredRequests = allRequests;
    if (specificDate != null) {
      final startUtc =
          DateTime(
            specificDate.year,
            specificDate.month,
            specificDate.day,
          ).toUtc();
      final endUtc = startUtc.add(const Duration(days: 1));
      filteredRequests =
          allRequests
              .where(
                (r) =>
                    r.createdAt.isAfter(startUtc) &&
                    r.createdAt.isBefore(endUtc),
              )
              .toList();
    } else if (dateRange != null && dateRange.length == 2) {
      final startUtc = dateRange[0].toUtc();
      final endUtc = dateRange[1].add(const Duration(days: 1)).toUtc();
      filteredRequests =
          allRequests
              .where(
                (r) =>
                    r.createdAt.isAfter(startUtc) &&
                    r.createdAt.isBefore(endUtc),
              )
              .toList();
    }

    if (userId != null) {
      filteredRequests =
          filteredRequests.where((r) => r.requesterId == userId).toList();
    }

    // Prepare request data with extra details
    final requestData = await Future.wait(
      filteredRequests.map((request) async {
        final item = await _firestoreService.getItemById(request.itemId);
        final user = await _firestoreService.getUser(request.requesterId);
        return {
          'type': 'Request',
          'itemName': item?.name ?? 'Unknown',
          'amount': request.quantity.toString(),
          'category': item?.category ?? 'N/A',
          'condition': 'N/A',
          'user': user?.email ?? 'Unknown',
          'status': request.status,
          'purpose': request.purpose ?? 'N/A',
          'reason': request.reason ?? 'N/A',
          'createdAt': DateFormat('yyyy-MM-dd').format(request.createdAt),
        };
      }),
    );

    // Prepare inventory data
    final inventoryData =
        filteredInventoryItems.map((item) {
          return {
            'type': 'Inventory',
            'itemName': item.name,
            'amount': item.amount.toString(),
            'category': item.category,
            'condition': item.condition ?? 'N/A',
            'user': item.userEmail ?? 'Unknown',
            'status': 'N/A',
            'purpose': 'N/A',
            'reason': 'N/A',
            'createdAt': DateFormat('yyyy-MM-dd').format(item.createdAt),
          };
        }).toList();

    // Combine and sort all data by date descending
    final allData = [...inventoryData, ...requestData];
    allData.sort((a, b) => b['createdAt']!.compareTo(a['createdAt']!));

    // Filters display text
    final userFilter = userId != null ? 'User: $userName' : 'All Users';
    final dateFilter =
        specificDate != null
            ? 'Date: ${DateFormat('yyyy-MM-dd').format(specificDate)}'
            : (dateRange != null && dateRange.length == 2)
            ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(dateRange[0])} to ${DateFormat('yyyy-MM-dd').format(dateRange[1])}'
            : 'All Dates';

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Inventory and Requests Report',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.Paragraph(text: userFilter),
              pw.Paragraph(text: dateFilter),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Type',
                  'Item',
                  'Amount',
                  'Category',
                  'Condition',
                  'User',
                  'Status',
                  'Purpose',
                  'Reason',
                  'Created At',
                ],
                data:
                    allData
                        .map(
                          (data) => [
                            data['type'],
                            data['itemName'],
                            data['amount'],
                            data['category'],
                            data['condition'],
                            data['user'],
                            data['status'],
                            data['purpose'],
                            data['reason'],
                            data['createdAt'],
                          ],
                        )
                        .toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Mizizi Learning Hub\nLavington, Nairobi, Kenya\nGenerated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\nAny Questions? admin@mizizilearning.com',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
      ),
    );

    // Save PDF to file
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Generates an Item Requests only report PDF
  /// Takes a list of ItemRequest objects (already fetched & filtered)
  Future<File> generateItemRequestsReport(List<ItemRequest> requests) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/item_requests_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Prepare data for the PDF table
    final requestData = await Future.wait(
      requests.map((request) async {
        final item = await _firestoreService.getItemById(request.itemId);
        final user = await _firestoreService.getUser(request.requesterId);
        return [
          item?.name ?? request.itemName,
          request.quantity.toString(),
          item?.category ?? 'N/A',
          user?.email ?? 'Unknown',
          request.status,
          request.purpose ?? 'N/A',
          request.reason ?? 'N/A',
          DateFormat('yyyy-MM-dd').format(request.createdAt),
        ];
      }),
    );

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Item Requests Report',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Item',
                  'Quantity',
                  'Category',
                  'Requester',
                  'Status',
                  'Purpose',
                  'Reason',
                  'Created At',
                ],
                data: requestData,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Mizizi Learning Hub\nLavington, Nairobi, Kenya\nGenerated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\nAny Questions? admin@mizizilearning.com',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
      ),
    );

    // Save PDF to file
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
