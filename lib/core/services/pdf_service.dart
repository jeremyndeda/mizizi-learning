import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inventory_item.dart';
import '../models/item_request.dart';
import 'firestore_service.dart';

class PdfService {
  final FirestoreService _firestoreService = FirestoreService();

  // Helper method to escape LaTeX special characters
  String _escapeLatex(String text) {
    if (text.isEmpty) return 'N/A';
    return text
        .replaceAll('&', '\\&')
        .replaceAll('%', '\\%')
        .replaceAll('\$', '\\\$')
        .replaceAll('#', '\\#')
        .replaceAll('_', '\\_')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('~', '\\textasciitilde{}')
        .replaceAll('^', '\\textasciicircum{}')
        .replaceAll('\n', ' ');
  }

  // Generate inventory report (updated to include item requests)
  Future<File> generateInventoryReport({
    String? userId,
    String? userName,
    DateTime? specificDate,
    List<DateTime>? dateRange,
  }) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/inventory_report_${DateTime.now().millisecondsSinceEpoch}.tex';
    final file = File(path);

    // Fetch inventory items
    final inventoryItems =
        userId != null
            ? await _firestoreService.getUserInventory(userId).first
            : await _firestoreService.getAllInventory().first;

    // Fetch item requests
    final allRequests = await _firestoreService.getAllItemRequests().first;

    // Filter inventory items
    List<InventoryItem> filteredInventoryItems = inventoryItems;
    if (specificDate != null) {
      final startOfDay = DateTime(
        specificDate.year,
        specificDate.month,
        specificDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      filteredInventoryItems =
          inventoryItems
              .where(
                (item) =>
                    item.createdAt.isAfter(startOfDay) &&
                    item.createdAt.isBefore(endOfDay),
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

    // Filter item requests
    List<ItemRequest> filteredRequests = allRequests;
    if (specificDate != null) {
      final startOfDay = DateTime(
        specificDate.year,
        specificDate.month,
        specificDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));
      filteredRequests =
          allRequests
              .where(
                (request) =>
                    request.createdAt.isAfter(startOfDay) &&
                    request.createdAt.isBefore(endOfDay),
              )
              .toList();
    } else if (dateRange != null) {
      filteredRequests =
          allRequests
              .where(
                (request) =>
                    request.createdAt.isAfter(dateRange[0]) &&
                    request.createdAt.isBefore(dateRange[1]),
              )
              .toList();
    }
    if (userId != null) {
      filteredRequests =
          allRequests
              .where((request) => request.requesterId == userId)
              .toList();
    }

    // Enrich request data with item names and requester emails
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

    // Prepare inventory item data
    final inventoryData =
        filteredInventoryItems
            .map(
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
                'createdAt': DateFormat('yyyy-MM-dd').format(item.createdAt),
              },
            )
            .toList();

    // Combine and sort data by creation date
    final allData = [...inventoryData, ...requestData];
    allData.sort(
      (a, b) => DateFormat('yyyy-MM-dd')
          .parse(b['createdAt']!)
          .compareTo(DateFormat('yyyy-MM-dd').parse(a['createdAt']!)),
    );

    final String userFilter = userId != null ? 'User: $userName' : 'All Users';
    final String dateFilter =
        specificDate != null
            ? 'Date: ${DateFormat('yyyy-MM-dd').format(specificDate)}'
            : dateRange != null
            ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(dateRange[0])} to ${DateFormat('yyyy-MM-dd').format(dateRange[1])}'
            : 'All Dates';

    final String latexContent = '''
\\documentclass[a4paper,12pt]{article}
\\usepackage{geometry}
\\geometry{margin=1in}
\\usepackage{booktabs}
\\usepackage{array}
\\usepackage{pdflscape}
\\usepackage{times}

\\begin{document}

% Title
\\begin{center}
    \\textbf{\\Large Inventory and Requests Report}
\\end{center}
\\vspace{0.5cm}

% Filter Details
\\begin{tabular}{l}
    \\textbf{Filter Details:} \\\\
    $userFilter \\\\
    $dateFilter
\\end{tabular}
\\vspace{0.5cm}

% Table
\\begin{landscape}
    \\begin{tabular}{|l|l|l|l|l|l|l|l|l|}
        \\hline
        \\textbf{Type} & \\textbf{Item} & \\textbf{Amount/Quantity} & \\textbf{Category} & \\textbf{Condition} & \\textbf{User/Requester} & \\textbf{Status} & \\textbf{Purpose} & \\textbf{Reason} & \\textbf{Created At} \\\\
        \\hline
        ${allData.map((data) => '${data['type']} & ${_escapeLatex(data['itemName']!)} & ${data['amount']} & ${_escapeLatex(data['category']!)} & ${_escapeLatex(data['condition']!)} & ${_escapeLatex(data['user']!)} & ${data['status']} & ${_escapeLatex(data['purpose']!)} & ${_escapeLatex(data['reason']!)} & ${data['createdAt']} \\\\ \\hline').join('\n')}
    \\end{tabular}
\\end{landscape}
\\vspace{0.5cm}

% Footer
\\begin{center}
    \\textbf{Mizizi Learning Hub} \\\\
    123 Green Lane, Nairobi, Kenya \\\\
    Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} \\\\
    Any Questions? support@mizizi.co.ke
\\end{center}

\\end{document}
''';

    await file.writeAsString(latexContent);
    return file;
  }

  // Generate item requests report (unchanged, kept for reference)
  Future<File> generateRequestsReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? requesterEmail,
  }) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/requests_report_${DateTime.now().millisecondsSinceEpoch}.tex';
    final file = File(path);

    // Fetch requester ID if email is provided
    String? requesterId;
    if (requesterEmail != null && requesterEmail.isNotEmpty) {
      final user = await _firestoreService.getUserByEmail(requesterEmail);
      requesterId = user?.uid;
    }

    // Fetch filtered requests
    final requests = await _firestoreService.getFilteredItemRequests(
      startDate: startDate,
      endDate: endDate,
      status: status,
      requesterId: requesterId,
    );

    // Sort by creation date (ascending)
    requests.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Fetch item names and requester emails
    final requestData = await Future.wait(
      requests.map((request) async {
        final item = await _firestoreService.getItemById(request.itemId);
        final user = await _firestoreService.getUser(request.requesterId);
        return {
          'itemName': item?.name ?? 'Unknown',
          'quantity': request.quantity.toString(),
          'requesterEmail': user?.email ?? 'Unknown',
          'status': request.status,
          'purpose': request.purpose ?? 'N/A',
          'reason': request.reason ?? 'N/A',
          'createdAt': DateFormat('yyyy-MM-dd').format(request.createdAt),
        };
      }),
    );

    // Prepare filter details for the report
    final String dateFilter =
        startDate != null && endDate != null
            ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}'
            : 'All Dates';
    final String statusFilter =
        status != null && status != 'All' ? 'Status: $status' : 'All Statuses';
    final String userFilter =
        requesterEmail != null && requesterEmail.isNotEmpty
            ? 'Requester: $requesterEmail'
            : 'All Requesters';

    final String latexContent = '''
\\documentclass[a4paper,12pt]{article}
\\usepackage{geometry}
\\geometry{margin=1in}
\\usepackage{booktabs}
\\usepackage{array}
\\usepackage{pdflscape}
\\usepackage{times}

\\begin{document}

% Title
\\begin{center}
    \\textbf{\\Large Item Requests Report}
\\end{center}
\\vspace{0.5cm}

% Filter Details
\\begin{tabular}{l}
    \\textbf{Filter Details:} \\\\
    $dateFilter \\\\
    $statusFilter \\\\
    $userFilter
\\end{tabular}
\\vspace{0.5cm}

% Table
\\begin{landscape}
    \\begin{tabular}{|l|l|l|l|l|l|l|}
        \\hline
        \\textbf{Item} & \\textbf{Quantity} & \\textbf{Requester} & \\textbf{Status} & \\textbf{Purpose} & \\textbf{Reason} & \\textbf{Created At} \\\\
        \\hline
        ${requestData.map((data) => '${_escapeLatex(data['itemName']!)} & ${data['quantity']} & ${_escapeLatex(data['requesterEmail']!)} & ${data['status']} & ${_escapeLatex(data['purpose']!)} & ${_escapeLatex(data['reason']!)} & ${data['createdAt']} \\\\ \\hline').join('\n')}
    \\end{tabular}
\\end{landscape}
\\vspace{0.5cm}

% Footer
\\begin{center}
    \\textbf{Mizizi Learning Hub} \\\\
    Lavington, Nairobi, Kenya \\\\
    Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())} \\\\
    Any Questions? admin@mizizilearning.com
\\end{center}

\\end{document}
''';

    await file.writeAsString(latexContent);
    return file;
  }
}
