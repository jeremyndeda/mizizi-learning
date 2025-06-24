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
import '../admin/add_user_screen.dart';

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
          }
        });
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final role = snapshot.data ?? 'user';
        List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.widgets),
            label: 'General Items',
          ),
        ];
        if (role == 'admin') {
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_add),
              label: 'Add User',
            ),
          );
        } else {
          navItems.add(
            const BottomNavigationBarItem(
              icon: Icon(Icons.reply),
              label: 'Return Item',
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: _buildDashboard(role),
          bottomNavigationBar: BottomNavigationBar(
            items: navItems,
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF4CAF50),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: AppTypography.bodyText,
            unselectedLabelStyle: AppTypography.caption,
            backgroundColor: Colors.white,
            elevation: 8,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }

  Widget _buildDashboard(String role) {
    return FutureBuilder(
      future: _firestoreService.getUser(_authService.currentUser!.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        String displayName = _authService.currentUser?.displayName ?? 'User';
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
              _authService.currentUser!.email!.substring(0, 1).toUpperCase();
        }

        final List<Widget> navigationCards = [
          if (role == 'admin')
            NavigationCard(
              title: 'All Inventory',
              icon: Icons.inventory,
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AllInventoryScreen(),
                    ),
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
                  MaterialPageRoute(
                    builder: (_) => const UserInventoryScreen(),
                  ),
                ),
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
          ),
          NavigationCard(
            title: 'Reports',
            icon: Icons.report,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(onLogout: _logout),
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
                    MaterialPageRoute(
                      builder: (_) => const RequestItemScreen(),
                    ),
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
        ];

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                        backgroundColor: Colors.grey[700],
                        radius: 24,
                        child: Text(
                          firstLetter,
                          style: AppTypography.heading2.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Welcome, $displayName',
                        style: AppTypography.heading2,
                        overflow: TextOverflow.ellipsis,
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
                                fontSize: 10,
                              ),
                            ),
                            showBadge: unreadCount > 0,
                            badgeStyle: const badges.BadgeStyle(
                              badgeColor: Colors.red,
                              padding: EdgeInsets.all(4),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.grey,
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
                    children: List.generate(navigationCards.length, (index) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        columnCount: 2,
                        duration: const Duration(milliseconds: 375),
                        child: ScaleAnimation(
                          child: FadeInAnimation(child: navigationCards[index]),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Recent Inventory', style: AppTypography.heading2),
                const SizedBox(height: 8),
                InventoryList(userId: _authService.currentUser!.uid),
              ],
            ),
          ),
        );
      },
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyText.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
