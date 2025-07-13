import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/typography.dart';
import '../../core/models/student.dart';
import '../../core/services/firestore_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  _StudentScreenState createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<Student> _students = [];
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterStudents);
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _firestoreService.getAllStudents().first;
      setState(() {
        _students = students;
        _filteredStudents = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading students: $e',
              style: AppTypography.bodyText,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _filterStudents() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredStudents = _students;
      });
      return;
    }

    setState(() {
      _filteredStudents =
          _students.where((student) {
            final nameMatch = student.name.toLowerCase().contains(query);
            final classMatch = student.className.toLowerCase().contains(query);
            return nameMatch || classMatch;
          }).toList();
    });
  }

  Future<void> _addStudent(String name, String className) async {
    final student = Student(
      id: const Uuid().v4(),
      name: name.trim(),
      className: className.trim(),
      createdAt: DateTime.now(),
    );
    try {
      await _firestoreService.addStudent(student);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Student added successfully',
              style: AppTypography.bodyText,
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error adding student: $e',
              style: AppTypography.bodyText,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateStudent(
    Student student,
    String newName,
    String newClass,
  ) async {
    try {
      await _firestoreService.updateStudent(student.id, {
        'name': newName,
        'className': newClass,
        'createdAt': Timestamp.fromDate(student.createdAt),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Student updated successfully',
              style: AppTypography.bodyText,
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating student: $e',
              style: AppTypography.bodyText,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteStudent(String id) async {
    try {
      await _firestoreService.deleteStudent(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Student deleted successfully',
              style: AppTypography.bodyText,
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      await _loadStudents();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting student: $e',
              style: AppTypography.bodyText,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddStudentDialog(
            onAddStudent: (name, className) async {
              await _addStudent(name, className);
            },
          ),
    );
  }

  void _showEditStudentDialog(Student student) {
    showDialog(
      context: context,
      builder:
          (context) => EditStudentDialog(
            student: student,
            onUpdate:
                (newName, newClass) =>
                    _updateStudent(student, newName, newClass),
          ),
    );
  }

  void _showDeleteStudentDialog(Student student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Delete Student', style: AppTypography.heading2),
            content: Text(
              'Are you sure you want to delete ${student.name}?',
              style: AppTypography.bodyText,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTypography.bodyText.copyWith(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _deleteStudent(student.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Delete', style: AppTypography.buttonText),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Manage Students', style: AppTypography.heading1),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        backgroundColor: Colors.transparent,
        elevation: 4,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.person_add, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimationLimiter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimationConfiguration.staggeredList(
                          position: 0,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: TextFormField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search by name or class',
                                  hintStyle: AppTypography.bodyText.copyWith(
                                    color: Colors.grey,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                ),
                                style: AppTypography.bodyText,
                                onChanged: (_) => _filterStudents(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          AnimationConfiguration.staggeredList(
                            position: 1,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTypography.bodyText.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child:
                              _filteredStudents.isEmpty
                                  ? AnimationConfiguration.staggeredList(
                                    position: 2,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Center(
                                          child: Text(
                                            'No students found',
                                            style: AppTypography.bodyText
                                                .copyWith(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  : StreamBuilder<List<Student>>(
                                    stream: _firestoreService.getAllStudents(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (snapshot.hasError) {
                                        return Text(
                                          'Error: ${snapshot.error}',
                                          style: AppTypography.bodyText
                                              .copyWith(color: Colors.red),
                                        );
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        return Text(
                                          'No students found',
                                          style: AppTypography.bodyText,
                                        );
                                      }
                                      final students =
                                          snapshot.data!
                                              .where(
                                                (student) =>
                                                    _filteredStudents.any(
                                                      (fs) =>
                                                          fs.id == student.id,
                                                    ),
                                              )
                                              .toList();
                                      return ListView.builder(
                                        itemCount: students.length,
                                        itemBuilder: (context, index) {
                                          final student = students[index];
                                          return AnimationConfiguration.staggeredList(
                                            position: index,
                                            duration: const Duration(
                                              milliseconds: 375,
                                            ),
                                            child: SlideAnimation(
                                              verticalOffset: 50.0,
                                              child: FadeInAnimation(
                                                child: StudentCard(
                                                  student: student,
                                                  onEdit:
                                                      () =>
                                                          _showEditStudentDialog(
                                                            student,
                                                          ),
                                                  onDelete:
                                                      () =>
                                                          _showDeleteStudentDialog(
                                                            student,
                                                          ),
                                                ),
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
                ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
  }
}

class AddStudentDialog extends StatefulWidget {
  final Function(String name, String className) onAddStudent;

  const AddStudentDialog({super.key, required this.onAddStudent});

  @override
  _AddStudentDialogState createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
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
        child: AnimationLimiter(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder:
                    (widget) => SlideAnimation(
                      verticalOffset: 20.0,
                      child: FadeInAnimation(child: widget),
                    ),
                children: [
                  Text(
                    'Add New Student',
                    style: AppTypography.heading2.copyWith(
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: AppTypography.bodyText.copyWith(
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    style: AppTypography.bodyText,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _classController,
                    decoration: InputDecoration(
                      labelText: 'Class',
                      labelStyle: AppTypography.bodyText.copyWith(
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                      ),
                    ),
                    style: AppTypography.bodyText,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a class';
                      }
                      return null;
                    },
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
                        onTap:
                            _isSubmitting
                                ? null
                                : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isSubmitting = true);
                                    await widget.onAddStudent(
                                      _nameController.text.trim(),
                                      _classController.text.trim(),
                                    );
                                    setState(() => _isSubmitting = false);
                                    Navigator.pop(context);
                                  }
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
                          child:
                              _isSubmitting
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    'Add Student',
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
          ),
        ),
      ),
    );
  }
}

class EditStudentDialog extends StatefulWidget {
  final Student student;
  final Function(String newName, String newClass) onUpdate;

  const EditStudentDialog({
    super.key,
    required this.student,
    required this.onUpdate,
  });

  @override
  _EditStudentDialogState createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<EditStudentDialog> {
  final _nameController = TextEditingController();
  final _classController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.student.name;
    _classController.text = widget.student.className;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
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
        child: AnimationLimiter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: AnimationConfiguration.toStaggeredList(
              duration: const Duration(milliseconds: 375),
              childAnimationBuilder:
                  (widget) => SlideAnimation(
                    verticalOffset: 20.0,
                    child: FadeInAnimation(child: widget),
                  ),
              children: [
                Text(
                  'Edit Student',
                  style: AppTypography.heading2.copyWith(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: AppTypography.bodyText.copyWith(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                    ),
                  ),
                  style: AppTypography.bodyText,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: 'Class',
                    labelStyle: AppTypography.bodyText.copyWith(
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50)),
                    ),
                  ),
                  style: AppTypography.bodyText,
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
                        widget.onUpdate(
                          _nameController.text.trim(),
                          _classController.text.trim(),
                        );
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
                          'Save',
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
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentCard({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF4CAF50),
                child: Text(
                  student.name.substring(0, 1).toUpperCase(),
                  style: AppTypography.bodyText.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: AppTypography.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Class: ${student.className}',
                      style: AppTypography.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
                tooltip: 'Edit Student',
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Delete Student',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
