import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/typography.dart';
import '../../core/models/activity.dart';
import '../../core/models/student.dart';
import '../../core/models/activity_register.dart';
import '../../core/services/firestore_service.dart';

class MarkRegisterDialog extends StatefulWidget {
  final Activity activity;
  final Function(ActivityRegister register) onMarkRegister;

  const MarkRegisterDialog({
    super.key,
    required this.activity,
    required this.onMarkRegister,
  });

  @override
  _MarkRegisterDialogState createState() => _MarkRegisterDialogState();
}

class _MarkRegisterDialogState extends State<MarkRegisterDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();
  List<Student> _students = [];
  Map<String, bool> _attendance = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _firestoreService.getAllStudents().first;
      setState(() {
        _students =
            students
                .where((s) => widget.activity.studentIds.contains(s.id))
                .toList();
        _attendance = {for (var student in _students) student.id: true};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mark Register for ${widget.activity.name}',
                      style: AppTypography.heading2.copyWith(
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Text(
                          'Date: ${_selectedDate.toString().split(' ')[0]}',
                          style: AppTypography.bodyText,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Select Date',
                            style: AppTypography.buttonText.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Students:',
                      style: AppTypography.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_students.isEmpty)
                      Text(
                        'No students assigned',
                        style: AppTypography.caption.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    if (_students.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            return CheckboxListTile(
                              title: Text(
                                student.name,
                                style: AppTypography.bodyText,
                              ),
                              subtitle: Text(
                                student.className,
                                style: AppTypography.caption,
                              ),
                              value: _attendance[student.id] ?? true,
                              onChanged: (bool? value) {
                                setState(() {
                                  _attendance[student.id] = value ?? true;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: AppTypography.bodyText.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final register = ActivityRegister(
                              id: const Uuid().v4(),
                              activityId: widget.activity.id,
                              date: _selectedDate,
                              attendance: _attendance,
                              createdAt: DateTime.now(),
                            );
                            widget.onMarkRegister(register);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Mark Register',
                              style: AppTypography.bodyText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }
} // TODO Implement this library.
