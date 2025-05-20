import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/request_screen.dart';
import '../screens/profile_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  UserModel? _user;
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));

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

  void _createActivity() async {
    final activity = ActivityModel(
      id: const Uuid().v4(),
      name: _nameController.text,
      description: _descriptionController.text,
      startDate: _startDate,
      endDate: _endDate,
      assignedUsers: [],
    );
    await FirestoreService().createActivity(activity);
    _nameController.clear();
    _descriptionController.clear();
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

  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Activities'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _user?.role == 'user'
                        ? StreamBuilder<List<ActivityModel>>(
                          stream: FirestoreService().getUserActivities(
                            FirebaseAuth.instance.currentUser!.uid,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No activities assigned.');
                            }
                            return ListView.builder(
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final activity = snapshot.data![index];
                                return CustomCard(
                                  child: ListTile(
                                    title: Text(activity.name),
                                    subtitle: Text(activity.description),
                                  ),
                                );
                              },
                            );
                          },
                        )
                        : Column(
                          children: [
                            CustomCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    CustomTextField(
                                      labelText: 'Name',
                                      controller: _nameController,
                                    ),
                                    CustomTextField(
                                      labelText: 'Description',
                                      controller: _descriptionController,
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _startDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2030),
                                        );
                                        if (date != null)
                                          setState(() => _startDate = date);
                                      },
                                      child: Text(
                                        'Start Date: ${_startDate.toString().split(' ')[0]}',
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _endDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime(2030),
                                        );
                                        if (date != null)
                                          setState(() => _endDate = date);
                                      },
                                      child: Text(
                                        'End Date: ${_endDate.toString().split(' ')[0]}',
                                      ),
                                    ),
                                    CustomButton(
                                      text: 'Create Activity',
                                      onPressed: _createActivity,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder<List<ActivityModel>>(
                                stream: FirestoreService().getAllActivities(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text('No activities found.');
                                  }
                                  return ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final activity = snapshot.data![index];
                                      return CustomCard(
                                        child: ListTile(
                                          title: Text(activity.name),
                                          subtitle: Text(activity.description),
                                        ),
                                      );
                                    },
                                  );
                                },
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
