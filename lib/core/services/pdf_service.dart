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

    final inventoryItems =
        userId != null
            ? await _firestoreService.getUserInventory(userId).first
            : await _firestoreService.getAllInventory().first;

    final allRequests = await _firestoreService.getAllItemRequests().first;

    List<InventoryItem> filteredInventoryItems = inventoryItems;
    if (specificDate != null) {
      final start = DateTime(
        specificDate.year,
        specificDate.month,
        specificDate.day,
      );
      final end = start.add(const Duration(days: 1));
      filteredInventoryItems =
          inventoryItems
              .where(
                (item) =>
                    item.createdAt.isAfter(start) &&
                    item.createdAt.isBefore(end),
              )
              .toList();
    } else if (dateRange != null) {
      filteredInventoryItems =
          inventoryItems
              .where(
                (item) =>
                    item.createdAt.isAfter(dateRange[0]) &&
                    item.createdAt.isBefore(dateRange[1]),
              )
              .toList();
    }

    List<ItemRequest> filteredRequests = allRequests;
    if (specificDate != null) {
      final start = DateTime(
        specificDate.year,
        specificDate.month,
        specificDate.day,
      );
      final end = start.add(const Duration(days: 1));
      filteredRequests =
          allRequests
              .where(
                (r) => r.createdAt.isAfter(start) && r.createdAt.isBefore(end),
              )
              .toList();
    } else if (dateRange != null) {
      filteredRequests =
          allRequests
              .where(
                (r) =>
                    r.createdAt.isAfter(dateRange[0]) &&
                    r.createdAt.isBefore(dateRange[1]),
              )
              .toList();
    }
    if (userId != null) {
      filteredRequests =
          filteredRequests.where((r) => r.requesterId == userId).toList();
    }

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

    final allData = [...inventoryData, ...requestData];
    allData.sort((a, b) => b['createdAt']!.compareTo(a['createdAt']!));

    final userFilter = userId != null ? 'User: $userName' : 'All Users';
    final dateFilter =
        specificDate != null
            ? 'Date: ${DateFormat('yyyy-MM-dd').format(specificDate)}'
            : dateRange != null
            ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(dateRange[0])} to ${DateFormat('yyyy-MM-dd').format(dateRange[1])}'
            : 'All Dates';

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

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> generateRequestsReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? requesterEmail,
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/requests_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    final allRequests = await _firestoreService.getAllItemRequests().first;

    List<ItemRequest> filtered = allRequests;

    if (startDate != null && endDate != null) {
      filtered =
          filtered
              .where(
                (r) =>
                    r.createdAt.isAfter(startDate) &&
                    r.createdAt.isBefore(endDate.add(const Duration(days: 1))),
              )
              .toList();
    }

    if (status != null && status != 'All') {
      filtered = filtered.where((r) => r.status == status).toList();
    }

    if (requesterEmail != null && requesterEmail.isNotEmpty) {
      final user = await _firestoreService.getUserByEmail(requesterEmail);
      if (user != null) {
        filtered = filtered.where((r) => r.requesterId == user.uid).toList();
      } else {
        filtered = [];
      }
    }

    final requestData = await Future.wait(
      filtered.map((request) async {
        final item = await _firestoreService.getItemById(request.itemId);
        final user = await _firestoreService.getUser(request.requesterId);
        return [
          item?.name ?? 'Unknown',
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
              pw.Paragraph(
                text:
                    'Filters - Status: ${status ?? 'All'}, '
                    'Requester: ${requesterEmail ?? 'All'}, '
                    'Date: ${startDate != null && endDate != null ? "${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}" : 'All'}',
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
                  'Mizizi Learning Hub\n Lavington, Nairobi, Kenya\nGenerated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}\nAny Questions? admin@mizizilearning.com',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
      ),
    );

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
