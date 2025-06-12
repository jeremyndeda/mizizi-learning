import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/models/item_request.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  // ignore: unused_field
  final AuthService _authService = AuthService();
  final PdfService _pdfService = PdfService();
  final Logger _logger = Logger('ManageRequestsScreen');
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  String? _selectedStatus = 'All';
  List<UserModel> _users = [];
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _firestoreService.searchUsersByEmail('');
      setState(() {
        _users = users;
      });
    } catch (e) {
      _logger.severe('Error loading users: $e');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E88E5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E88E5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedUserId = null;
      _selectedStatus = 'All';
      _searchController.clear();
      _isSearchExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Requests', style: AppTypography.heading2),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
            tooltip: _isSearchExpanded ? 'Close Search' : 'Search Requests',
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _resetFilters();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: () async {
              try {
                final requests = await _firestoreService
                    .getFilteredItemRequests(
                      startDate: _startDate,
                      endDate: _endDate,
                      status: _selectedStatus == 'All' ? null : _selectedStatus,
                      requesterId: _selectedUserId,
                    );

                final file = await _pdfService.generateItemRequestsReport(
                  requests,
                );
                await Share.shareXFiles([
                  XFile(file.path),
                ], text: 'Item Requests Report');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate PDF: $e')),
                );
                _logger.severe('Error generating PDF: $e');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchExpanded)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _searchController,
                          labelText: 'Search by User Email',
                          onChanged: (value) async {
                            final users = await _firestoreService
                                .searchUsersByEmail(value);
                            setState(() {
                              _users = users;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _selectedStatus,
                        hint: const Text('Status'),
                        items:
                            ['All', 'Pending', 'Approved', 'Rejected']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Select User'),
                          value: _selectedUserId,
                          items:
                              _users
                                  .map(
                                    (user) => DropdownMenuItem(
                                      value: user.uid,
                                      child: Text(user.email),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedUserId = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        text:
                            _startDate == null
                                ? 'Select Date Range'
                                : '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
                        onPressed: () => _selectDateRange(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    text: 'Reset Filters',
                    onPressed: _resetFilters,
                    backgroundColor: Colors.redAccent,
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<ItemRequest>>(
              future: _firestoreService.getFilteredItemRequests(
                startDate: _startDate,
                endDate: _endDate,
                status: _selectedStatus == 'All' ? null : _selectedStatus,
                requesterId: _selectedUserId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No requests found'));
                }

                final requests = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return FutureBuilder(
                      future: _firestoreService.getUser(request.requesterId),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (userSnapshot.hasError) {
                          return _buildRequestCard(
                            context,
                            request,
                            'Error loading user data',
                          );
                        }

                        final requesterEmail =
                            userSnapshot.data?.email ?? 'Unknown User';
                        return _buildRequestCard(
                          context,
                          request,
                          requesterEmail,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    ItemRequest request,
    String requesterEmail,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Item: ${request.itemName}',
                    style: AppTypography.bodyText.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status,
                    style: AppTypography.bodyText.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${request.quantity}',
              style: AppTypography.bodyText.copyWith(color: Colors.black54),
            ),
            Text(
              'Requester: $requesterEmail',
              style: AppTypography.bodyText.copyWith(color: Colors.black54),
            ),
            if (request.purpose != null)
              Text(
                'Purpose: ${request.purpose}',
                style: AppTypography.bodyText.copyWith(color: Colors.black54),
              ),
            if (request.reason != null)
              Text(
                'Reason: ${request.reason}',
                style: AppTypography.bodyText.copyWith(color: Colors.black54),
              ),
            if (request.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      backgroundColor: Colors.green,
                      onPressed: () async {
                        _logger.info('Approving request ID: ${request.id}');
                        try {
                          final item = await _firestoreService.getItemByName(
                            request.itemName,
                          );

                          if (item != null) {
                            if (item.amount < request.quantity) {
                              _logger.warning(
                                'Insufficient quantity: ${item.amount} available, ${request.quantity} requested',
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Insufficient quantity available',
                                  ),
                                ),
                              );
                              return;
                            }

                            await _firestoreService.updateInventoryItem(
                              item.id,
                              {'amount': item.amount - request.quantity},
                            );

                            final newItem = InventoryItem(
                              id: const Uuid().v4(),
                              name: item.name,
                              condition: item.condition,
                              category: item.category,
                              userId: request.requesterId,
                              userEmail: requesterEmail,
                              createdAt: DateTime.now(),
                              description: item.description,
                              location: item.location,
                              amount: request.quantity,
                            );
                            await _firestoreService.addInventoryItem(newItem);

                            await _firestoreService.updateItemRequestStatus(
                              request.id,
                              'approved',
                              itemId: item.id,
                            );
                          } else {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Item Not Found'),
                                    content: Text(
                                      'The item "${request.itemName}" does not exist in inventory.\n'
                                      'Would you like to create it and assign it to the requester?',
                                      style: AppTypography.bodyText,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      CustomButton(
                                        text: 'Create Item',
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm != true) return;

                            final newItemId = const Uuid().v4();
                            final newItem = InventoryItem(
                              id: newItemId,
                              name: request.itemName,
                              condition: 'Good',
                              category: 'Other',
                              userId: request.requesterId,
                              userEmail: requesterEmail,
                              createdAt: DateTime.now(),
                              description:
                                  request.purpose ?? 'No description provided',
                              location: 'Unknown',
                              amount: request.quantity,
                            );
                            await _firestoreService.addInventoryItem(newItem);

                            await _firestoreService.updateItemRequestStatus(
                              request.id,
                              'approved',
                              itemId: newItemId,
                            );
                          }

                          await _notificationService.sendInventoryNotification(
                            request.requesterId,
                            'Request Approved',
                            'Your request for ${request.quantity} of ${request.itemName} has been approved.',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request approved successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          _logger.severe('Error during approval process: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to approve request: $e'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      backgroundColor: Colors.redAccent,
                      onPressed: () async {
                        final reasonController = TextEditingController();
                        final result = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Reject Request'),
                                content: CustomTextField(
                                  controller: reasonController,
                                  labelText: 'Reason for Rejection',
                                  //
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  CustomButton(
                                    text: 'Submit',
                                    onPressed: () {
                                      if (reasonController.text
                                          .trim()
                                          .isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please provide a reason',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.pop(
                                        context,
                                        reasonController.text.trim(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                        );
                        if (result != null) {
                          await _firestoreService.updateItemRequestStatus(
                            request.id,
                            'rejected',
                            reason: result,
                          );
                          await _notificationService.sendInventoryNotification(
                            request.requesterId,
                            'Request Rejected',
                            'Your request for ${request.quantity} of ${request.itemName} was rejected: $result',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Request rejected successfully'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
