import 'package:flutter/material.dart';
import '../../core/constants/typography.dart';
import '../../core/models/activity.dart';
import '../../core/models/user_model.dart';
import '../../core/models/student.dart';
import '../../core/services/firestore_service.dart';

class ActivityDetailsDialog extends StatefulWidget {
  final Activity activity;

  const ActivityDetailsDialog({super.key, required this.activity});

  @override
  _ActivityDetailsDialogState createState() => _ActivityDetailsDialogState();
}

class _ActivityDetailsDialogState extends State<ActivityDetailsDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _teacher;
  List<Student> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacher = await _firestoreService.getUser(
        widget.activity.teacherId,
      );
      final students = await _firestoreService.getAllStudents().first;
      setState(() {
        _teacher = teacher;
        _students =
            students
                .where((s) => widget.activity.studentIds.contains(s.id))
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading details: $e';
        _isLoading = false;
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
                      widget.activity.name,
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
                    Text(
                      'Teacher: ${_teacher?.name ?? _teacher?.email.split('@')[0] ?? 'Unknown'}',
                      style: AppTypography.bodyText,
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
                            return ListTile(
                              title: Text(
                                student.name,
                                style: AppTypography.bodyText,
                              ),
                              subtitle: Text(
                                student.className,
                                style: AppTypography.caption,
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Close',
                          style: AppTypography.bodyText.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
} // TODO Implement this library.
