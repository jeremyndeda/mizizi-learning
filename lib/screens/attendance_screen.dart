import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../screens/dashboard_screen.dart';
import '../screens/request_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/profile_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  UserModel? _user;
  bool _isLoading = true;
  String? _checkInTime;
  String? _checkOutTime;
  String? _totalDuration;
  String _status = 'Not Checked In';

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

  void _checkInOut() {
    final now = DateTime.now();
    if (_checkInTime == null) {
      setState(() {
        _checkInTime = now.toString();
        _status = 'Checked In';
      });
    } else if (_checkOutTime == null) {
      setState(() {
        _checkOutTime = now.toString();
        _totalDuration =
            '${now.difference(DateTime.parse(_checkInTime!)).inMinutes} minutes';
        _status = 'Checked Out';
      });
    } else {
      setState(() {
        _checkInTime = now.toString();
        _checkOutTime = null;
        _totalDuration = null;
        _status = 'Checked In';
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

  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (_user?.role == 'user') ...[
                      CustomCard(
                        child: Column(
                          children: [
                            CustomButton(
                              text:
                                  _checkOutTime == null
                                      ? 'Check In/Out'
                                      : 'Reset',
                              onPressed: _checkInOut,
                            ),
                            const SizedBox(height: 16),
                            Text('Today\'s Record'),
                            ListTile(title: Text('Check In: $_checkInTime')),
                            ListTile(title: Text('Check Out: $_checkOutTime')),
                            ListTile(
                              title: Text('Total Duration: $_totalDuration'),
                            ),
                            ListTile(title: Text('Status: $_status')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomCard(
                        child: const Text('Calendar View (To be implemented)'),
                      ),
                    ] else if (_user?.role == 'admin') ...[
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
                                DropdownMenuItem(
                                  value: 'user2',
                                  child: Text('User 2'),
                                ),
                              ],
                              onChanged: (value) {},
                            ),
                            DropdownButton<String>(
                              value: null,
                              hint: const Text('Filter by Date Range'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'today',
                                  child: Text('Today'),
                                ),
                                DropdownMenuItem(
                                  value: 'week',
                                  child: Text('This Week'),
                                ),
                              ],
                              onChanged: (value) {},
                            ),
                            DropdownButton<String>(
                              value: null,
                              hint: const Text('Filter by Activity'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'activity1',
                                  child: Text('Activity 1'),
                                ),
                              ],
                              onChanged: (value) {},
                            ),
                            CustomButton(
                              text: 'Print/Export PDF',
                              onPressed: () {},
                            ),
                            CustomButton(
                              text: 'Mark/Edit Attendance',
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
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
