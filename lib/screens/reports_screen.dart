import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child:
                    _user?.role == 'admin'
                        ? Column(
                          children: [
                            CustomCard(
                              child: Column(
                                children: [
                                  DropdownButton<String>(
                                    value: null,
                                    hint: const Text('Report Type'),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'attendance',
                                        child: Text('Attendance'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'inventory',
                                        child: Text('Inventory'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'requests',
                                        child: Text('Requests'),
                                      ),
                                    ],
                                    onChanged: (value) {},
                                  ),
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
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  CustomButton(
                                    text: 'Export to PDF',
                                    onPressed: () {},
                                  ),
                                  CustomButton(
                                    text: 'Export to Excel',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        : const Center(child: Text('Access Denied')),
              ),
    );
  }
}
