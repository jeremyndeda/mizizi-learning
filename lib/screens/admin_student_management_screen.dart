import 'package:flutter/material.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class AdminStudentManagementScreen extends StatefulWidget {
  const AdminStudentManagementScreen({super.key});

  @override
  _AdminStudentManagementScreenState createState() =>
      _AdminStudentManagementScreenState();
}

class _AdminStudentManagementScreenState
    extends State<AdminStudentManagementScreen> {
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  String? _filterClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F2E8),
      appBar: AppBar(
        title: const Text('Manage Students'),
        backgroundColor: const Color(0xFF6A8D73),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              child: Column(
                children: [
                  CustomTextField(
                    labelText: 'Search by Name',
                    controller: TextEditingController(),
                  ),
                  DropdownButton<String>(
                    value: _filterClass,
                    hint: const Text('Filter by Class'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Class 1',
                        child: Text('Class 1'),
                      ),
                      DropdownMenuItem(
                        value: 'Class 2',
                        child: Text('Class 2'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _filterClass = value),
                  ),
                  CustomButton(
                    text: 'Add Student',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Add Student'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomTextField(
                                    labelText: 'Full Name',
                                    controller: _nameController,
                                  ),
                                  CustomTextField(
                                    labelText: 'Class/Grade',
                                    controller: _classController,
                                  ),
                                ],
                              ),
                              actions: [
                                CustomButton(text: 'Save', onPressed: () {}),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  CustomCard(
                    child: ListTile(
                      title: const Text('Student 1 - Class 1'),
                      subtitle: const Text('Assigned Activities: Sports Day'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.event),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
