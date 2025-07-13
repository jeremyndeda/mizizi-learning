// ignore_for_file: unused_import

import 'dart:io';
import 'package:Mizizi/core/models/activity_register.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/inventory_item.dart';
import '../models/item_request.dart';
import '../models/activity.dart';
import '../models/user_model.dart';
import '../models/student.dart';
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
        String itemName;
        String category;
        if (request.itemId.isNotEmpty) {
          final item = await _firestoreService.getItemById(request.itemId);
          itemName = item?.name ?? request.itemName;
          category = item?.category ?? 'N/A';
        } else {
          itemName = request.itemName;
          category = 'N/A';
        }
        final user = await _firestoreService.getUser(request.requesterId);
        return {
          'type': 'Request',
          'itemName': itemName,
          'amount': request.quantity.toString(),
          'category': category,
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
  /// Supports filtering by userId or dateRange
  Future<File> generateItemRequestsReport({
    String? userId,
    String? userName,
    List<DateTime>? dateRange,
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/item_requests_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Fetch filtered requests
    final requests = await _firestoreService.getFilteredItemRequests(
      startDate:
          dateRange != null && dateRange.length == 2 ? dateRange[0] : null,
      endDate: dateRange != null && dateRange.length == 2 ? dateRange[1] : null,
      status: null,
      requesterId: userId,
    );

    // Prepare data for the PDF table
    final requestData = await Future.wait(
      requests.map((request) async {
        String itemName;
        String category;
        if (request.itemId.isNotEmpty) {
          final item = await _firestoreService.getItemById(request.itemId);
          itemName = item?.name ?? request.itemName;
          category = item?.category ?? 'N/A';
        } else {
          itemName = request.itemName;
          category = 'N/A';
        }
        final user = await _firestoreService.getUser(request.requesterId);
        return [
          itemName,
          request.quantity.toString(),
          category,
          user?.email ?? 'Unknown',
          request.status,
          request.purpose ?? 'N/A',
          request.reason ?? 'N/A',
          DateFormat('yyyy-MM-dd').format(request.createdAt),
        ];
      }),
    );

    // Filters display text
    final userFilter = userId != null ? 'User: $userName' : 'All Users';
    final dateFilter =
        dateRange != null && dateRange.length == 2
            ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(dateRange[0])} to ${DateFormat('yyyy-MM-dd').format(dateRange[1])}'
            : 'All Dates';

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
              pw.Paragraph(text: userFilter),
              pw.Paragraph(text: dateFilter),
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

  /// Generates a General Items Request Report PDF
  /// Supports filtering by userId or all users, with totals per item
  Future<File> generateGeneralItemsReport({
    String? userId,
    String? userName,
    DateTime? specificDate,
    List<DateTime>? dateRange,
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/general_items_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Fetch filtered requests
    final filteredRequests = await _firestoreService.getFilteredItemRequests(
      startDate:
          dateRange != null && dateRange.length == 2
              ? dateRange[0]
              : specificDate,
      endDate:
          dateRange != null && dateRange.length == 2
              ? dateRange[1]
              : specificDate?.add(const Duration(days: 1)),
      status: null,
      requesterId: userId,
    );

    // Prepare request data
    final requestData = await Future.wait(
      filteredRequests.map((request) async {
        final generalItem = await _firestoreService.getGeneralItemById(
          request.itemId,
        );
        final user = await _firestoreService.getUser(request.requesterId);
        return {
          'itemName': generalItem?.name ?? request.itemName,
          'packagingType': generalItem?.packagingType ?? 'N/A',
          'quantity': request.quantity,
          'user': user?.email ?? 'Unknown',
          'status': request.status,
          'createdAt': DateFormat('yyyy-MM-dd').format(request.createdAt),
        };
      }),
    );

    // Calculate totals per item
    final itemTotals = <String, int>{};
    for (var data in requestData) {
      final itemName = data['itemName'] as String;
      final quantity = data['quantity'] as int;
      itemTotals[itemName] = (itemTotals[itemName] ?? 0) + quantity;
    }

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
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'General Items Request Report',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.Paragraph(text: userFilter),
              pw.Paragraph(text: dateFilter),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Item',
                  'Packaging',
                  'Quantity',
                  'User',
                  'Status',
                  'Created At',
                ],
                data:
                    requestData
                        .map(
                          (data) => [
                            data['itemName'],
                            data['packagingType'],
                            data['quantity'].toString(),
                            data['user'],
                            data['status'],
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
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Item Totals',
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
              pw.TableHelper.fromTextArray(
                headers: ['Item', 'Total Quantity'],
                data:
                    itemTotals.entries
                        .map((e) => [e.key, e.value.toString()])
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

  /// Generates an Activity Report PDF
  /// Supports filtering by activityId, teacherId, studentId, or all activities
  Future<File> generateActivityReport({
    String? activityId,
    String? teacherId,
    String? studentId,
    String?
    filterName, // Name of activity, teacher, or student for report title
  }) async {
    final pdf = pw.Document();
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/activity_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);

    // Fetch activities based on filter
    List<Activity> activities;
    if (activityId != null) {
      final activity = await _firestoreService.getActivityById(activityId);
      activities = activity != null ? [activity] : [];
    } else if (teacherId != null) {
      activities = await _firestoreService.getUserActivities(teacherId).first;
    } else if (studentId != null) {
      activities = await _firestoreService.getAllActivities().first;
      activities =
          activities.where((a) => a.studentIds.contains(studentId)).toList();
    } else {
      activities = await _firestoreService.getAllActivities().first;
    }

    // Prepare activity data
    final activityData = await Future.wait(
      activities.map((activity) async {
        final teacher = await _firestoreService.getUser(activity.teacherId);
        final students = await Future.wait(
          activity.studentIds.map((id) async {
            final student = await _firestoreService.getStudentById(id);
            return student?.name ?? 'Unknown';
          }),
        );
        return [
          activity.name,
          activity.description,
          teacher?.email ?? 'Unknown',
          students.join(', ') == '' ? 'None' : students.join(', '),
          DateFormat('yyyy-MM-dd').format(activity.createdAt),
        ];
      }),
    );

    // Filters display text
    final filterText =
        activityId != null
            ? 'Activity: $filterName'
            : teacherId != null
            ? 'Teacher: $filterName'
            : studentId != null
            ? 'Student: $filterName'
            : 'All Activities';

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Activity Report',
                  style: pw.TextStyle(fontSize: 24),
                ),
              ),
              pw.Paragraph(text: filterText),
              if (activityData.isEmpty)
                pw.Paragraph(
                  text: 'No activities found for the selected filter.',
                ),
              if (activityData.isNotEmpty)
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Name',
                    'Description',
                    'Teacher',
                    'Students',
                    'Created At',
                  ],
                  data: activityData,
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

/// Generates an Activity Report PDF
/// Supports filtering by activityId, teacherId, studentId, or all activities
Future<File> generateActivityReport({
  String? activityId,
  String? teacherId,
  String? studentId,
  String? filterName,
}) async {
  final pdf = pw.Document();
  final directory = await getTemporaryDirectory();
  final filePath =
      '${directory.path}/activity_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(filePath);

  // Create FirestoreService instance
  final FirestoreService firestoreService = FirestoreService();

  // Fetch activities based on filter
  List<Activity> activities;
  if (activityId != null) {
    final activity = await firestoreService.getActivityById(activityId);
    activities = activity != null ? [activity] : [];
  } else if (teacherId != null) {
    activities = await firestoreService.getUserActivities(teacherId).first;
  } else if (studentId != null) {
    activities = await firestoreService.getAllActivities().first;
    activities =
        activities.where((a) => a.studentIds.contains(studentId)).toList();
  } else {
    activities = await firestoreService.getAllActivities().first;
  }

  // Prepare activity data with registers
  final activityData = await Future.wait(
    activities.map((activity) async {
      final teacher = await firestoreService.getUser(activity.teacherId);
      final registers =
          await firestoreService.getActivityRegisters(activity.id).first;
      final studentNames = await Future.wait(
        activity.studentIds.map((id) async {
          final student = await firestoreService.getStudentById(id);
          return student?.name ?? 'Unknown';
        }),
      );
      // Summarize attendance from all registers
      int presentCount = 0;
      int absentCount = 0;
      for (final register in registers) {
        for (final attendance in register.attendance.values) {
          if (attendance) {
            presentCount++;
          } else {
            absentCount++;
          }
        }
      }
      final registerSummary =
          registers.isNotEmpty
              ? '$presentCount Present, $absentCount Absent'
              : 'No Registers';
      return {
        'name': activity.name,
        'description': activity.description,
        'teacher': teacher?.name ?? teacher?.email.split('@')[0] ?? 'Unknown',
        'students': studentNames.join(', '),
        'registerSummary': registerSummary,
        'createdAt': DateFormat('yyyy-MM-dd').format(activity.createdAt),
      };
    }),
  );

  // Filter display text
  final filterText = filterName ?? 'All Activities';

  // Build PDF content
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build:
          (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Activity Report',
                style: pw.TextStyle(fontSize: 24),
              ),
            ),
            pw.Paragraph(text: 'Filter: $filterText'),
            pw.TableHelper.fromTextArray(
              headers: [
                'Activity Name',
                'Description',
                'Teacher',
                'Students',
                'Register Summary',
                'Created At',
              ],
              data:
                  activityData
                      .map(
                        (data) => [
                          data['name'],
                          data['description'],
                          data['teacher'],
                          data['students'],
                          data['registerSummary'],
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

/// Generates a Register Report PDF for a specific activity
Future<File> generateRegisterReport({required Activity activity}) async {
  final pdf = pw.Document();
  final directory = await getTemporaryDirectory();
  final filePath =
      '${directory.path}/register_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File(filePath);

  // Create FirestoreService instance
  final firestoreService = FirestoreService();

  // Fetch registers for the activity
  final registers =
      await firestoreService.getActivityRegisters(activity.id).first;

  // Group registers by date
  final Map<DateTime, List<ActivityRegister>> groupedRegisters = {};
  for (var register in registers) {
    final date = DateTime(
      register.date.year,
      register.date.month,
      register.date.day,
    );
    groupedRegisters[date] = groupedRegisters[date] ?? [];
    groupedRegisters[date]!.add(register);
  }

  // Prepare data for each register
  final registerData = await Future.wait(
    groupedRegisters.entries.map((entry) async {
      final date = entry.key;
      final dateRegisters = entry.value;
      final dateData = await Future.wait(
        dateRegisters.asMap().entries.map((regEntry) async {
          final register = regEntry.value;
          final students = await firestoreService.getAllStudents().first;
          final attendanceData = await Future.wait(
            register.attendance.entries.map((att) async {
              final student = students.firstWhere(
                (s) => s.id == att.key,
                orElse:
                    () => Student(
                      id: att.key,
                      name: 'Unknown',
                      className: 'N/A',
                      createdAt: DateTime.now(),
                    ),
              );
              return {
                'studentName': student.name,
                'className': student.className,
                'status': att.value ? 'Present' : 'Absent',
              };
            }),
          );
          return {
            'registerTime': DateFormat('HH:mm').format(register.date),
            'attendance': attendanceData,
          };
        }),
      );
      return {
        'date': DateFormat('MMMM dd, yyyy').format(date),
        'registers': dateData,
      };
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
                'Register Report - ${activity.name}',
                style: pw.TextStyle(fontSize: 24),
              ),
            ),
            pw.Paragraph(text: 'Activity: ${activity.name}'),
            pw.SizedBox(height: 10),
            for (var dateEntry in registerData) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  dateEntry['date'] as String,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              for (var reg in (dateEntry['registers'] as List)) ...[
                pw.Text(
                  'Register at ${reg['registerTime']}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.TableHelper.fromTextArray(
                  headers: ['Student Name', 'Class', 'Status'],
                  data:
                      (reg['attendance'] as List)
                          .map(
                            (att) => [
                              att['studentName'],
                              att['className'],
                              att['status'],
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
                pw.SizedBox(height: 10),
              ],
            ],
            if (registerData.isEmpty)
              pw.Text(
                'No registers found',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontStyle: pw.FontStyle.italic,
                ),
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
