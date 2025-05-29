import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../auth/login_screen.dart';
import '../dashboard/components/inventory_list.dart';
import '../dashboard/components/navigation_card.dart';
import '../dashboard/components/welcome_card.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../inventory/user_inventory_screen.dart';
import '../inventory/all_inventory_screen.dart';
import '../inventory/request_item_screen.dart';
import '../inventory/manage_requests_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  // ignore: unused_field
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboard(),
      const NotificationsScreen(),
      ProfileScreen(onLogout: _logout),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboard() {
    return FutureBuilder<String>(
      future: _authService.getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final role = snapshot.data ?? 'user';
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WelcomeCard(
                  userId: _authService.currentUser!.uid,
                  onNotificationsTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (role == 'admin') ...[
                  NavigationCard(
                    title: 'All Inventory',
                    icon: Icons.inventory,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AllInventoryScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                NavigationCard(
                  title: 'My Inventory',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserInventoryScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                NavigationCard(
                  title: 'Reports',
                  icon: Icons.report,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileScreen(onLogout: _logout),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (role == 'user' || role == 'care') ...[
                  NavigationCard(
                    title: 'Request Item',
                    icon: Icons.add_shopping_cart,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestItemScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (role == 'admin') ...[
                  NavigationCard(
                    title: 'Manage Requests',
                    icon: Icons.list_alt,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManageRequestsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                InventoryList(userId: _authService.currentUser!.uid),
              ],
            ),
          ),
        );
      },
    );
  }
}
