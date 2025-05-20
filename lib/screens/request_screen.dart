import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/request_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../screens/dashboard_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/profile_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  UserModel? _user;
  bool _isLoading = true;
  final _descriptionController = TextEditingController();
  String _type = 'Item';
  String _priority = 'Low';
  String? _relatedItem;

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

  void _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final request = RequestModel(
        id: const Uuid().v4(),
        userId: user.uid,
        type: _type,
        description: _descriptionController.text,
        priority: _priority,
        relatedItem: _relatedItem,
        status: 'Pending',
        createdAt: DateTime.now(),
      );
      await FirestoreService().createRequest(request);
      _descriptionController.clear();
      setState(() {
        _type = 'Item';
        _priority = 'Low';
        _relatedItem = null;
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

  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Requests'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _user?.role == 'user'
                        ? Column(
                          children: [
                            CustomCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    DropdownButton<String>(
                                      value: _type,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Item',
                                          child: Text('Item'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Repair',
                                          child: Text('Repair'),
                                        ),
                                      ],
                                      onChanged:
                                          (value) =>
                                              setState(() => _type = value!),
                                    ),
                                    CustomTextField(
                                      labelText: 'Description',
                                      controller: _descriptionController,
                                    ),
                                    DropdownButton<String>(
                                      value: _priority,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Low',
                                          child: Text('Low'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Medium',
                                          child: Text('Medium'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'High',
                                          child: Text('High'),
                                        ),
                                      ],
                                      onChanged:
                                          (value) => setState(
                                            () => _priority = value!,
                                          ),
                                    ),
                                    CustomButton(
                                      text: 'Submit Request',
                                      onPressed: _submitRequest,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: StreamBuilder<List<RequestModel>>(
                                stream: FirestoreService().getUserRequests(
                                  FirebaseAuth.instance.currentUser!.uid,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text('No requests found.');
                                  }
                                  return ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final request = snapshot.data![index];
                                      return CustomCard(
                                        child: ListTile(
                                          title: Text(
                                            '${request.type} - ${request.status}',
                                          ),
                                          subtitle: Text(request.description),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
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
                                    hint: const Text('Filter by Status'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Pending',
                                        child: Text('Pending'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Approved',
                                        child: Text('Approved'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Archived',
                                        child: Text('Archived'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  DropdownButton<String>(
                                    value: null,
                                    hint: const Text('Filter by Type'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Item',
                                        child: Text('Item'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Repair',
                                        child: Text('Repair'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  CustomButton(
                                    text: 'Print Report',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: StreamBuilder<List<RequestModel>>(
                                stream: FirestoreService().getAllRequests(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const Text('No requests found.');
                                  }
                                  return ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final request = snapshot.data![index];
                                      return CustomCard(
                                        child: ListTile(
                                          title: Text(
                                            '${request.type} - ${request.status}',
                                          ),
                                          subtitle: Text(request.description),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.check),
                                                onPressed:
                                                    () => FirestoreService()
                                                        .updateRequestStatus(
                                                          request.id,
                                                          'Approved',
                                                        ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.archive),
                                                onPressed:
                                                    () => FirestoreService()
                                                        .updateRequestStatus(
                                                          request.id,
                                                          'Archived',
                                                        ),
                                              ),
                                            ],
                                          ),
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
