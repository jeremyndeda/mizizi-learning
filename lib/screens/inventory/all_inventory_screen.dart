import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'issue_dialog.dart';

class AllInventoryScreen extends StatefulWidget {
  const AllInventoryScreen({super.key});

  @override
  State<AllInventoryScreen> createState() => _AllInventoryScreenState();
}

class _AllInventoryScreenState extends State<AllInventoryScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  final PdfService _pdfService = PdfService();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String itemId,
    String itemName,
    String userId,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm Deletion', style: AppTypography.heading2),
            content: Text(
              'Are you sure you want to delete "$itemName"? This action cannot be undone.',
              style: AppTypography.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: AppTypography.buttonText),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      try {
        await _firestoreService.deleteInventoryItem(itemId);
        await _notificationService.sendInventoryNotification(
          userId,
          'Item Deleted',
          'Item $itemName has been deleted.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '"$itemName" deleted successfully',
                style: AppTypography.bodyText,
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting item: $e',
                style: AppTypography.bodyText,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data ?? 'user';
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('All Inventory', style: AppTypography.heading1),
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
            body: Center(
              child: Text(
                'Only admins can view all inventory items.',
                style: AppTypography.bodyText.copyWith(color: Colors.grey),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text('All Inventory', style: AppTypography.heading1),
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
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                tooltip: 'Generate Full Inventory PDF',
                onPressed: () async {
                  try {
                    final file = await _pdfService.generateInventoryReport();
                    await Share.shareXFiles([
                      XFile(file.path),
                    ], text: 'Inventory Report');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to generate PDF: $e',
                            style: AppTypography.bodyText,
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by item name',
                    hintStyle: AppTypography.caption.copyWith(
                      color: Colors.grey,
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                            : null,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                  ),
                  style: AppTypography.bodyText,
                ),
              ),
              Expanded(
                child: StreamBuilder<List<InventoryItem>>(
                  stream: _firestoreService.getAllInventory(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final items =
                        snapshot.data!
                            .where(
                              (item) => item.name.toLowerCase().contains(
                                _searchQuery,
                              ),
                            )
                            .toList();
                    final totalItems = items.length;
                    final start = _currentPage * _itemsPerPage;
                    final end = (_currentPage + 1) * _itemsPerPage;
                    final pagedItems = items.sublist(
                      start,
                      end > totalItems ? totalItems : end,
                    );

                    if (pagedItems.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No items found.'
                              : 'No items match your search.',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: AnimationLimiter(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: pagedItems.length,
                              itemBuilder: (context, index) {
                                final item = pagedItems[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: InventoryCard(
                                        item: item,
                                        currentUserRole: role,
                                        onEdit: () {
                                          if (_authService.currentUser?.uid ==
                                              item.userId) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => AddEditItemScreen(
                                                      userId: item.userId,
                                                      item: item,
                                                    ),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'You can only edit your own items',
                                                  style: AppTypography.bodyText,
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        onDelete:
                                            () => _confirmDelete(
                                              context,
                                              item.id,
                                              item.name,
                                              item.userId,
                                            ),
                                        onIssue: () {
                                          if ((role == 'admin' ||
                                                  role == 'care') &&
                                              _authService.currentUser?.uid ==
                                                  item.userId &&
                                              item.amount > 0) {
                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) =>
                                                      IssueDialog(item: item),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'You can only issue your own items with available amount',
                                                  style: AppTypography.bodyText,
                                                ),
                                                backgroundColor: Colors.red,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _currentPage > 0
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey[300],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Previous',
                                  style: AppTypography.buttonText,
                                ),
                              ),
                              Text(
                                'Page ${_currentPage + 1} of ${(totalItems / _itemsPerPage).ceil()}',
                                style: AppTypography.bodyText,
                              ),
                              ElevatedButton(
                                onPressed:
                                    end < totalItems
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      end < totalItems
                                          ? const Color(0xFF4CAF50)
                                          : Colors.grey[300],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Next',
                                  style: AppTypography.buttonText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
