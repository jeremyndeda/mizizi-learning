import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/request_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/profile_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _user?.role == 'user'
                        ? ListView(
                          children: [
                            CustomCard(
                              child: ListTile(
                                title: const Text(
                                  'Item 1 - Good - Electronics',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.request_page),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            CustomButton(
                              text: 'Add New Item',
                              onPressed: () {},
                            ),
                          ],
                        )
                        : Column(
                          children: [
                            CustomCard(
                              child: Column(
                                children: [
                                  DropdownButton<String>(
                                    value: null,
                                    hint: const Text('Filter by User'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'user1',
                                        child: Text('User 1'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  DropdownButton<String>(
                                    value: null,
                                    hint: const Text('Filter by Category'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'electronics',
                                        child: Text('Electronics'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  DropdownButton<String>(
                                    value: null,
                                    hint: const Text('Filter by Condition'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'good',
                                        child: Text('Good'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  CustomButton(
                                    text: 'Add Global Item',
                                    onPressed: () {},
                                  ),
                                  CustomButton(
                                    text: 'Export Inventory',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                            CustomCard(
                              child: const Text(
                                'All Inventories (To be implemented)',
                              ),
                            ),
                          ],
                        ),
              ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
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
        selectedItemColor: const Color(0xFFD4A017),
        unselectedItemColor: const Color(0xFF6A8D73),
        backgroundColor: const Color(0xFFF9F2E8),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
