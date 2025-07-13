import 'package:Mizizi/screens/student/student_screen.dart';
import 'package:Mizizi/screens/activity/activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../core/constants/typography.dart';
import '../../core/models/notification_model.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/components/inventory_list.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../inventory/user_inventory_screen.dart';
import '../inventory/all_inventory_screen.dart';
import '../inventory/request_item_screen.dart';
import '../inventory/manage_requests_screen.dart';
import '../inventory/general_items_screen.dart';
import '../inventory/return_item_screen.dart';
import '../admin/add_user_screen.dart';
import '../repair/repair_request_screen.dart';
import '../repair/manage_repairs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error logging out: $e',
              style: AppTypography.bodyText.copyWith(color: Colors.white),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GeneralItemsScreen()),
        );
        break;
      case 1:
        _authService.getUserRole().then((role) {
          if (role == 'admin') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddUserScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReturnItemScreen()),
            );
          }
        });
        break;
      case 2:
        if (_authService.currentUser!.uid.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => ManageRepairsScreen(
                    currentUserId: _authService.currentUser!.uid,
                  ),
            ),
          );
        }
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
                strokeWidth: 3,
              ),
            ),
          );
        }
        final role = snapshot.data ?? 'user';
        List<BottomNavigationBarItem> navItems = [
          BottomNavigationBarItem(
            icon: const Icon(Icons.widgets, size: 28),
            label: 'General Items',
            tooltip: 'View General Items',
          ),
          if (role == 'admin')
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_add, size: 28),
              label: 'Add User',
              tooltip: 'Add New User',
            )
          else
            BottomNavigationBarItem(
              icon: const Icon(Icons.reply, size: 28),
              label: 'Return Item',
              tooltip: 'Return an Item',
            ),
          if (role == 'admin')
            BottomNavigationBarItem(
              icon: const Icon(Icons.build, size: 28),
              label: 'Manage Repairs',
              tooltip: 'Manage Repair Requests',
            ),
          if (role == 'admin')
            BottomNavigationBarItem(
              icon: const Icon(Icons.school, size: 28),
              label: 'Students',
              tooltip: 'Manage Students',
            ),
        ];

        return FutureBuilder(
          future: _firestoreService.getUser(_authService.currentUser!.uid),
          builder: (context, userSnapshot) {
            String displayName =
                _authService.currentUser?.displayName ?? 'User';
            String firstLetter = 'X';

            if (userSnapshot.hasData && userSnapshot.data != null) {
              final user = userSnapshot.data!;
              displayName = user.name ?? user.email.split('@')[0];
              firstLetter =
                  (user.name != null && user.name!.isNotEmpty)
                      ? user.name!.substring(0, 1).toUpperCase()
                      : user.email.substring(0, 1).toUpperCase();
            } else if (_authService.currentUser?.email != null) {
              displayName = _authService.currentUser!.email!.split('@')[0];
              firstLetter =
                  _authService.currentUser!.email!
                      .substring(0, 1)
                      .toUpperCase();
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: _buildDashboard(role, displayName, firstLetter),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  items: navItems,
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white70,
                  selectedLabelStyle: AppTypography.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: AppTypography.caption.copyWith(
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  onTap: _onItemTapped,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard(String role, String displayName, String firstLetter) {
    final List<Widget> navigationCards = [
      if (role == 'admin')
        NavigationCard(
          title: 'All Inventory',
          icon: Icons.inventory,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllInventoryScreen()),
              ),
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          ),
        ),
      NavigationCard(
        title: 'My Inventory',
        icon: Icons.person,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserInventoryScreen()),
            ),
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
        ),
      ),
      NavigationCard(
        title: 'Extra-Curricular Activity',
        icon: Icons.event,
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ActivityScreen(
                      currentUserId: _authService.currentUser!.uid,
                    ),
              ),
            ),
        gradient: const LinearGradient(
          colors: [Color(0xFFF57C00), Color(0xFFEF6C00)],
        ),
      ),
      if (role == 'user' || role == 'care')
        NavigationCard(
          title: 'Request Item',
          icon: Icons.add_shopping_cart,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestItemScreen()),
              ),
          gradient: const LinearGradient(
            colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
          ),
        ),
      if (role == 'admin')
        NavigationCard(
          title: 'Manage Requests',
          icon: Icons.list_alt,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ManageRequestsScreen(
                        currentUserId: _authService.currentUser!.uid,
                      ),
                ),
              ),
          gradient: const LinearGradient(
            colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
          ),
        ),
      if (role == 'user' || role == 'care')
        NavigationCard(
          title: 'Request Repair',
          icon: Icons.build,
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RepairRequestScreen()),
              ),
          gradient: const LinearGradient(
            colors: [Color(0xFF009688), Color(0xFF00796B)],
          ),
        ),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(onLogout: _logout),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFF4CAF50),
                    radius: 28,
                    child: Text(
                      firstLetter,
                      style: AppTypography.heading2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $displayName',
                        style: AppTypography.heading2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        role == 'admin' ? 'Administrator' : 'User',
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<List<NotificationModel>>(
                  stream: _firestoreService.getUserNotifications(
                    _authService.currentUser!.uid,
                  ),
                  builder: (context, snapshot) {
                    int unreadCount = 0;
                    if (snapshot.hasData) {
                      unreadCount =
                          snapshot.data!.where((n) => !n.isRead).length;
                    }
                    return IconButton(
                      icon: badges.Badge(
                        badgeContent: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        showBadge: unreadCount > 0,
                        badgeStyle: const badges.BadgeStyle(
                          badgeColor: Color(0xFFE57373),
                          padding: EdgeInsets.all(6),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Color(0xFF4CAF50),
                          size: 28,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Notifications',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            AnimationLimiter(
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: List.generate(navigationCards.length, (index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    columnCount: 2,
                    duration: const Duration(milliseconds: 400),
                    child: ScaleAnimation(
                      scale: 0.95,
                      child: FadeInAnimation(child: navigationCards[index]),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Inventory',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            InventoryList(userId: _authService.currentUser!.uid),
          ],
        ),
      ),
    );
  }
}

class NavigationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  const NavigationCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
