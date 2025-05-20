import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../screens/attendance_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/request_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  bool _isLoading = true;
  int _selectedIndex = 0;

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirestoreService().getUser(user.uid);
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AttendanceScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ActivityScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RequestScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A8D73),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Welcome, ${_user?.email.split('@')[0]}! Role: ${_user?.role}',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick Stats',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    CustomCard(
                      child: Column(
                        children: const [
                          ListTile(title: Text('Today’s Attendance: 85%')),
                          ListTile(title: Text('Pending Requests: 3')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children:
                            _user?.role == 'admin'
                                ? [
                                  CustomCard(
                                    child: ListTile(
                                      leading: const Icon(Icons.inventory),
                                      title: const Text('All Inventory'),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const InventoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  CustomCard(
                                    child: ListTile(
                                      leading: const Icon(Icons.people),
                                      title: const Text('User Inventories'),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const InventoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]
                                : [
                                  CustomCard(
                                    child: ListTile(
                                      leading: const Icon(Icons.inventory),
                                      title: const Text('My Inventory'),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const InventoryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  CustomCard(
                                    child: ListTile(
                                      leading: const Icon(Icons.access_time),
                                      title: const Text('My Attendance'),
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const AttendanceScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Activities'),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(
          0xFFD4A017,
        ), // New accent color for visibility
        unselectedItemColor: const Color(0xFF6A8D73),
        backgroundColor: const Color(0xFFF9F2E8),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
