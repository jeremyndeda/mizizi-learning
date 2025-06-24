import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/typography.dart';
import '../../core/models/inventory_item.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/widgets/inventory_card.dart';
import 'add_edit_item_screen.dart';
import 'issue_dialog.dart';

class UserInventoryScreen extends StatefulWidget {
  const UserInventoryScreen({super.key});

  @override
  State<UserInventoryScreen> createState() => _UserInventoryScreenState();
}

class _UserInventoryScreenState extends State<UserInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Inventory', style: AppTypography.heading1),
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
                hintText: 'Search items...',
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
                  (context, TextEditingValue value, child) =>
                      UserInventoryItemsList(
                        searchQuery: value.text.toLowerCase(),
                        userId: userId,
                        authService: _authService,
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditItemScreen(userId: userId),
            ),
          );
        },
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 4,
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class UserInventoryItemsList extends StatefulWidget {
  final String searchQuery;
  final String userId;
  final AuthService authService;

  const UserInventoryItemsList({
    super.key,
    required this.searchQuery,
    required this.userId,
    required this.authService,
  });

  @override
  State<UserInventoryItemsList> createState() => _UserInventoryItemsListState();
}

class _UserInventoryItemsListState extends State<UserInventoryItemsList> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

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
            title: const Text(
              'Confirm Deletion',
              style: AppTypography.heading2,
            ),
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
      future: widget.authService.getUserRole(),
      builder: (context, roleSnapshot) {
        if (roleSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = roleSnapshot.data ?? 'user';
        return StreamBuilder<List<InventoryItem>>(
          stream: _firestoreService.getUserInventory(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: AppTypography.bodyText.copyWith(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items =
                snapshot.data!
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(widget.searchQuery),
                    )
                    .toList();

            if (items.isEmpty) {
              return Center(
                child: Text(
                  widget.searchQuery.isEmpty
                      ? 'No items in your inventory'
                      : 'No items match your search',
                  style: AppTypography.bodyText.copyWith(color: Colors.grey),
                ),
              );
            }

            return AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: FutureBuilder<UserModel?>(
                          future: _firestoreService.getUser(item.userId),
                          builder: (context, userSnapshot) {
                            String ownerName = 'Unknown';
                            if (userSnapshot.hasData &&
                                userSnapshot.data != null) {
                              ownerName =
                                  userSnapshot.data!.name ??
                                  userSnapshot.data!.email;
                            }
                            return InventoryCard(
                              item: item,
                              currentUserRole: role,
                              ownerName: ownerName,
                              onEdit:
                                  item.userId == widget.userId
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => AddEditItemScreen(
                                                  userId: widget.userId,
                                                  item: item,
                                                ),
                                          ),
                                        );
                                      }
                                      : null,
                              onDelete:
                                  item.userId == widget.userId
                                      ? () => _confirmDelete(
                                        context,
                                        item.id,
                                        item.name,
                                        widget.userId,
                                      )
                                      : null,
                              onIssue: () {
                                if ((role == 'admin' || role == 'care') &&
                                    widget.userId == item.userId &&
                                    item.amount > 0) {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => IssueDialog(item: item),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'You can only issue your own items with available amount',
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
                              },
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
      },
    );
  }
}
