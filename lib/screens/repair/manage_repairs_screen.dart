import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/typography.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/repair_request.dart';
import '../../core/models/user_model.dart';

class ManageRepairsScreen extends StatefulWidget {
  final String currentUserId;

  const ManageRepairsScreen({super.key, required this.currentUserId});

  @override
  _ManageRepairsScreenState createState() => _ManageRepairsScreenState();
}

class _ManageRepairsScreenState extends State<ManageRepairsScreen> {
  // ignore: unused_field
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Manage Repair Requests',
          style: AppTypography.heading1,
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search repair requests...',
                hintStyle: AppTypography.caption.copyWith(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                ),
                suffixIcon: ValueListenableBuilder(
                  valueListenable: _searchController,
                  builder:
                      (context, TextEditingValue value, child) =>
                          value.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                              : const SizedBox.shrink(),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
              style: AppTypography.bodyText,
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _searchController,
              builder:
                  (context, TextEditingValue value, child) => RepairRequestList(
                    searchQuery: value.text.toLowerCase(),
                    currentUserId: widget.currentUserId,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class RepairRequestList extends StatefulWidget {
  final String searchQuery;
  final String currentUserId;

  const RepairRequestList({
    super.key,
    required this.searchQuery,
    required this.currentUserId,
  });

  @override
  _RepairRequestListState createState() => _RepairRequestListState();
}

class _RepairRequestListState extends State<RepairRequestList> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showActionDialog(
    BuildContext context,
    RepairRequest request,
  ) async {
    final TextEditingController _estimationController = TextEditingController();
    final TextEditingController _reasonController = TextEditingController();

    final bool? actionTaken = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Manage ${request.itemName} Request',
              style: AppTypography.heading2,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (request.status == 'pending') ...[
                    TextField(
                      controller: _estimationController,
                      decoration: InputDecoration(
                        labelText: 'Repair Estimation',
                        hintText: 'Enter estimated cost/time',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: AppTypography.bodyText,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason (for decline)',
                        hintText: 'Enter reason for declining',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: AppTypography.bodyText,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (request.status == 'pending') ...[
                ElevatedButton(
                  onPressed: () async {
                    await _firestoreService.updateRepairRequestStatus(
                      request.id,
                      'approved',
                      estimation:
                          _estimationController.text.trim().isEmpty
                              ? null
                              : _estimationController.text.trim(),
                    );
                    await _firestoreService.sendInventoryNotification(
                      request.requesterId,
                      'Repair Request Approved',
                      'Your repair request for ${request.itemName} has been approved.',
                      type: 'repair_request',
                      data: {'repairRequestId': request.id},
                    );
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Approve', style: AppTypography.buttonText),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Please provide a reason for declining',
                            style: AppTypography.bodyText,
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      return;
                    }
                    await _firestoreService.updateRepairRequestStatus(
                      request.id,
                      'declined',
                      reason: reason,
                    );
                    await _firestoreService.sendInventoryNotification(
                      request.requesterId,
                      'Repair Request Declined',
                      'Your repair request for ${request.itemName} was declined. Reason: $reason',
                      type: 'repair_request',
                      data: {'repairRequestId': request.id},
                    );
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Decline', style: AppTypography.buttonText),
                ),
              ],
              ElevatedButton(
                onPressed: () async {
                  await _firestoreService.deleteRepairRequest(request.id);
                  await _firestoreService.sendInventoryNotification(
                    request.requesterId,
                    'Repair Request Deleted',
                    'Your repair request for ${request.itemName} has been deleted.',
                    type: 'repair_request',
                    data: {'repairRequestId': request.id},
                  );
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Delete', style: AppTypography.buttonText),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
    );

    _estimationController.dispose();
    _reasonController.dispose();

    if (actionTaken == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Action performed on ${request.itemName} request',
            style: AppTypography.bodyText,
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RepairRequest>>(
      stream: _firestoreService.getAllRepairRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: AppTypography.bodyText.copyWith(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              widget.searchQuery.isEmpty
                  ? 'No repair requests found'
                  : 'No repair requests match your search',
              style: AppTypography.bodyText.copyWith(color: Colors.grey),
            ),
          );
        }

        final requests =
            snapshot.data!
                .where(
                  (request) =>
                      request.itemName.toLowerCase().contains(
                        widget.searchQuery,
                      ) ||
                      request.description.toLowerCase().contains(
                        widget.searchQuery,
                      ),
                )
                .toList();

        if (requests.isEmpty) {
          return Center(
            child: Text(
              'No repair requests match your search',
              style: AppTypography.bodyText.copyWith(color: Colors.grey),
            ),
          );
        }

        return AnimationLimiter(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: FutureBuilder<UserModel?>(
                      future: _firestoreService.getUser(request.requesterId),
                      builder: (context, userSnapshot) {
                        String requesterName = 'Unknown';
                        if (userSnapshot.hasData && userSnapshot.data != null) {
                          requesterName =
                              userSnapshot.data!.name ??
                              userSnapshot.data!.email;
                        }
                        return RepairRequestCard(
                          request: request,
                          requesterName: requesterName,
                          onTap: () => _showActionDialog(context, request),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class RepairRequestCard extends StatelessWidget {
  final RepairRequest request;
  final String requesterName;
  final VoidCallback onTap;

  const RepairRequestCard({
    super.key,
    required this.request,
    required this.requesterName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      request.itemName,
                      style: AppTypography.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Requester: $requesterName',
                style: AppTypography.caption.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Description: ${request.description}',
                style: AppTypography.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (request.location != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Location: ${request.location}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (request.estimation != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Estimation: ${request.estimation}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (request.reason != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Reason: ${request.reason}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
