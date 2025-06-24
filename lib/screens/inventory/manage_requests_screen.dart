import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/models/item_request.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class ManageRequestsScreen extends StatefulWidget {
  final String currentUserId; // Added to pass current user's ID
  const ManageRequestsScreen({super.key, required this.currentUserId});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final PdfService _pdfService = PdfService();
  final Logger _logger = Logger('ManageRequestsScreen');
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedUserId;
  String? _selectedUserName;
  String _selectedStatus = 'All';
  List<String> _userEmails = [];
  List<String> _filteredEmails = [];
  bool _isSearchExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmails();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserEmails() async {
    setState(() => _isLoading = true);
    try {
      final emails = await _firestoreService.getAllUserEmails();
      if (mounted) {
        setState(() {
          _userEmails = emails;
          _filteredEmails = emails;
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Error loading user emails: $e');
      if (mounted) {
        _showSnackBar('Failed to load user emails: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEmails =
          _userEmails
              .where((email) => email.toLowerCase().contains(query))
              .toList();
      if (query.isEmpty) {
        _selectedUserId = null;
        _selectedUserName = null;
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
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
          ),
    );
    if (picked != null && mounted) {
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
      _selectedUserName = null;
      _selectedStatus = 'All';
      _searchController.clear();
      _isSearchExpanded = false;
      _filteredEmails = _userEmails;
    });
  }

  Future<void> _handlePdfDownload({
    bool byUser = false,
    bool byDate = false,
  }) async {
    setState(() => _isLoading = true);
    try {
      final file = await _pdfService.generateItemRequestsReport(
        userId: byUser ? _selectedUserId : null,
        userName: byUser ? _selectedUserName : 'All Users',
        dateRange:
            byDate && _startDate != null && _endDate != null
                ? [_startDate!, _endDate!]
                : null,
      );
      _showSnackBar(
        'PDF downloaded to ${file.path}',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _logger.severe('Error generating PDF: $e');
      _showSnackBar('Failed to generate PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPdfOptionsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Download PDF Report'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All Requests (All Users)'),
                  onTap: () {
                    Navigator.pop(context);
                    _handlePdfDownload();
                  },
                ),
                if (_selectedUserId != null)
                  ListTile(
                    title: Text(
                      'Requests for ${_selectedUserName ?? _searchController.text}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handlePdfDownload(byUser: true);
                    },
                  ),
                if (_startDate != null && _endDate != null)
                  ListTile(
                    title: const Text('By Date Range'),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handlePdfDownload(byDate: true);
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteRequest(
    String requestId,
    String requesterId,
    String itemName,
    int quantity,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete this request for $quantity of $itemName?',
              style: AppTypography.bodyText,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyText.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              CustomButton(
                text: 'Delete',
                backgroundColor: Colors.redAccent,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.deleteItemRequest(requestId);
      await _notificationService.sendInventoryNotification(
        requesterId,
        'Request Deleted',
        'Your request for $quantity of $itemName has been deleted by an admin.',
      );
      _showSnackBar(
        'Request deleted successfully',
        backgroundColor: Colors.redAccent,
      );
    } catch (e) {
      _logger.severe('Error deleting request: $e');
      _showSnackBar('Failed to delete request: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(
    ItemRequest request,
    String requesterEmail,
  ) async {
    setState(() => _isLoading = true);
    try {
      // Fetch the current user's inventory
      final userInventory =
          await _firestoreService.getUserInventory(widget.currentUserId).first;
      final item = userInventory.firstWhere(
        (item) => item.name.toLowerCase() == request.itemName.toLowerCase(),
        orElse:
            () => InventoryItem(
              id: '',
              name: '',
              amount: 0,
              userId: '',
              createdAt: DateTime.now(),
              category: '',
            ),
      );

      if (item.id.isNotEmpty) {
        if (item.amount < request.quantity) {
          _logger.warning(
            'Insufficient quantity: ${item.amount} available, ${request.quantity} requested',
          );
          _showSnackBar('Insufficient quantity available in your inventory');
          return;
        }
        // Update the admin's inventory
        await _firestoreService.updateInventoryItem(item.id, {
          'amount': item.amount - request.quantity,
        });
        // Create new inventory item for the requester
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
                  'The item "${request.itemName}" does not exist in your inventory.\nWould you like to create it and assign it to the requester?',
                  style: AppTypography.bodyText,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  CustomButton(
                    text: 'Create Item',
                    onPressed: () => Navigator.pop(context, true),
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
          description: request.purpose ?? 'No description provided',
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
      _showSnackBar(
        'Request approved successfully',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      _logger.severe('Error during approval process: $e');
      _showSnackBar('Failed to approve request: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectRequest(ItemRequest request) async {
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Request'),
            content: CustomTextField(
              controller: reasonController,
              labelText: 'Reason for Rejection',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              CustomButton(
                text: 'Submit',
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    _showSnackBar('Please provide a reason');
                    return;
                  }
                  Navigator.pop(context, reasonController.text.trim());
                },
              ),
            ],
          ),
    );
    if (result != null && mounted) {
      setState(() => _isLoading = true);
      try {
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
        _showSnackBar(
          'Request rejected successfully',
          backgroundColor: Colors.redAccent,
        );
      } catch (e) {
        _logger.severe('Error rejecting request: $e');
        _showSnackBar('Failed to reject request: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
    reasonController.dispose();
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
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
                if (!_isSearchExpanded) _resetFilters();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download PDF Report',
            onPressed: _isLoading ? null : _showPdfOptionsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isSearchExpanded)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_filteredEmails.isNotEmpty) {
                            showModalBottomSheet(
                              context: context,
                              builder:
                                  (context) => ListView.builder(
                                    itemCount: _filteredEmails.length,
                                    itemBuilder: (context, index) {
                                      final email = _filteredEmails[index];
                                      return ListTile(
                                        title: Text(email),
                                        onTap: () async {
                                          setState(() => _isLoading = true);
                                          try {
                                            final user = await _firestoreService
                                                .getUserByEmail(email);
                                            if (user != null && mounted) {
                                              setState(() {
                                                _selectedUserId = user.uid;
                                                _selectedUserName =
                                                    user.name ?? user.email;
                                                _searchController.text = email;
                                                _filteredEmails = _userEmails;
                                              });
                                            }
                                          } catch (e) {
                                            _logger.severe(
                                              'Error selecting user: $e',
                                            );
                                            _showSnackBar(
                                              'Failed to select user: $e',
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _isLoading = false,
                                              );
                                            }
                                          }
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                            );
                          }
                        },
                        child: AbsorbPointer(
                          child: CustomTextField(
                            controller: _searchController,
                            labelText: 'Search by User Email',
                            enabled: !_isLoading,
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _selectedUserId = null;
                                          _selectedUserName = null;
                                        });
                                      },
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
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
                              onChanged:
                                  _isLoading
                                      ? null
                                      : (value) {
                                        if (value != null && mounted) {
                                          setState(
                                            () => _selectedStatus = value,
                                          );
                                        }
                                      },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomButton(
                            text:
                                _startDate == null
                                    ? 'Select Date Range'
                                    : '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}',
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _selectDateRange(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Reset Filters',
                        onPressed: _isLoading ? null : _resetFilters,
                        backgroundColor: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<ItemRequest>>(
                  stream: _firestoreService.streamFilteredItemRequests(
                    startDate: _startDate,
                    endDate: _endDate,
                    status:
                        _selectedStatus == 'All'
                            ? null
                            : _selectedStatus.toLowerCase(),
                    requesterId: _selectedUserId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: AppTypography.bodyText,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No requests found',
                          style: AppTypography.bodyText,
                        ),
                      );
                    }

                    final requests = snapshot.data!;
                    // Sort by createdAt (newest first)
                    final sortedRequests =
                        requests.toList()
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: sortedRequests.length,
                      itemBuilder: (context, index) {
                        final request = sortedRequests[index];
                        return FutureBuilder<UserModel?>(
                          future: _firestoreService.getUser(
                            request.requesterId,
                          ),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.status.toLowerCase() == 'pending') ...[
                  Expanded(
                    child: CustomButton(
                      text: 'Approve',
                      backgroundColor: Colors.green,
                      onPressed:
                          _isLoading
                              ? null
                              : () => _approveRequest(request, requesterEmail),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Reject',
                      backgroundColor: Colors.redAccent,
                      onPressed:
                          _isLoading ? null : () => _rejectRequest(request),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CustomButton(
                  text: 'Delete',
                  backgroundColor: Colors.red,
                  onPressed:
                      _isLoading
                          ? null
                          : () => _deleteRequest(
                            request.id,
                            request.requesterId,
                            request.itemName,
                            request.quantity,
                          ),
                ),
              ],
            ),
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
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
