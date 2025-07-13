// ignore_for_file: unused_import

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/typography.dart';
import '../../core/models/activity.dart';
import '../../core/models/user_model.dart';
import '../../core/models/student.dart';
import '../../core/models/activity_register.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/pdf_service.dart';
import 'activity_details_dialog.dart';
import 'mark_register_dialog.dart';
import 'register_list_screen.dart';

class ActivityScreen extends StatefulWidget {
  final String currentUserId;

  const ActivityScreen({super.key, required this.currentUserId});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final PdfService _pdfService = PdfService();
  final _searchController = TextEditingController();
  List<Activity> _filteredActivities = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false;
  final Logger _logger = Logger('ActivityScreen');

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _searchController.addListener(_filterActivities);
    _logger.info(
      'ActivityScreen initialized for user: ${widget.currentUserId}',
    );
  }

  Future<void> _checkAdminStatus() async {
    final role = await _authService.getUserRole();
    setState(() {
      _isAdmin = role == 'admin';
      _isLoading = false;
    });
    _logger.info('User role: ${role}, isAdmin: $_isAdmin');
  }

  void _filterActivities() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredActivities =
          _filteredActivities.where((activity) {
            final nameMatch = activity.name.toLowerCase().contains(query);
            final descriptionMatch = activity.description
                .toLowerCase()
                .contains(query);
            return nameMatch || descriptionMatch;
          }).toList();
    });
    _logger.info('Filtered activities count: ${_filteredActivities.length}');
  }

  void _showAddActivityDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddActivityDialog(
            onAddActivity: (name, description, teacherId) async {
              final activity = Activity(
                id: const Uuid().v4(),
                name: name.trim(),
                description: description.trim(),
                teacherId: teacherId,
                studentIds: [],
                createdAt: DateTime.now(),
              );
              try {
                await _firestoreService.addActivity(activity);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Activity added successfully',
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
                _logger.info('Activity added: ${activity.name}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error adding activity: $e',
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
                _logger.severe('Error adding activity: $e');
              }
            },
          ),
    );
  }

  void _showEditActivityDialog(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AddActivityDialog(
            activity: activity,
            onAddActivity: (newName, newDescription, newTeacherId) async {
              try {
                await _firestoreService.updateActivity(activity.id, {
                  'name': newName,
                  'description': newDescription,
                  'teacherId': newTeacherId,
                  'studentIds': activity.studentIds,
                  'createdAt': Timestamp.fromDate(activity.createdAt),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Activity updated successfully',
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
                _logger.info('Activity updated: ${activity.name}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error updating activity: $e',
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
                _logger.severe('Error updating activity: $e');
              }
            },
          ),
    );
  }

  void _showAssignStudentsDialog(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AssignStudentsDialog(
            activity: activity,
            onAssignStudents: (selectedStudentIds) async {
              try {
                await _firestoreService.updateActivity(activity.id, {
                  'name': activity.name,
                  'description': activity.description,
                  'teacherId': activity.teacherId,
                  'studentIds': selectedStudentIds,
                  'createdAt': Timestamp.fromDate(activity.createdAt),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Students assigned successfully',
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
                _logger.info('Students assigned to activity: ${activity.name}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error assigning students: $e',
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
                _logger.severe('Error assigning students: $e');
              }
            },
          ),
    );
  }

  void _showDeleteActivityDialog(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Delete Activity', style: AppTypography.heading2),
            content: Text(
              'Are you sure you want to delete ${activity.name}?',
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
                  try {
                    await _firestoreService.deleteActivity(activity.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Activity deleted successfully',
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
                    Navigator.pop(context);
                    _logger.info('Activity deleted: ${activity.name}');
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting activity: $e',
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
                    _logger.severe('Error deleting activity: $e');
                  }
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

  void _showDetailsDialog(Activity activity) {
    showDialog(
      context: context,
      builder: (context) => ActivityDetailsDialog(activity: activity),
    );
  }

  void _showMarkRegisterDialog(Activity activity) {
    showDialog(
      context: context,
      builder:
          (context) => MarkRegisterDialog(
            activity: activity,
            onMarkRegister: (register) async {
              try {
                await _firestoreService.addActivityRegister(register);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Register marked successfully',
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
                _logger.info('Register marked for activity: ${activity.name}');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error marking register: $e',
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
                _logger.severe('Error marking register: $e');
              }
            },
          ),
    );
  }

  void _showRegisterList(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterListScreen(activity: activity),
      ),
    );
  }

  void _showGenerateReportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => GenerateReportDialog(
            activities: _filteredActivities,
            onGenerateReport: (type, id, name) async {
              try {
                File pdfFile;
                switch (type) {
                  case 'single':
                    pdfFile = await _pdfService.generateActivityReport(
                      activityId: id,
                      filterName: name,
                    );
                    break;
                  case 'teacher':
                    pdfFile = await _pdfService.generateActivityReport(
                      teacherId: id,
                      filterName: name,
                    );
                    break;
                  case 'student':
                    pdfFile = await _pdfService.generateActivityReport(
                      studentId: id,
                      filterName: name,
                    );
                    break;
                  default:
                    pdfFile = await _pdfService.generateActivityReport(
                      filterName: 'All Activities',
                    );
                }
                await Share.shareXFiles([
                  XFile(pdfFile.path),
                ], text: 'Activity Report - $name');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Activity report generated and shared successfully',
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
                _logger.info(
                  'Activity report generated and shared: $type - $name',
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error generating report: $e',
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
                _logger.severe('Error generating report: $e');
              }
            },
          ),
    );
  }

  Future<void> _refreshActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _logger.info('Refreshing activities');
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Activities', style: AppTypography.heading1),
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
        actions:
            _isAdmin
                ? [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    onPressed: _showGenerateReportDialog,
                    tooltip: 'Generate PDF Report',
                  ),
                ]
                : null,
      ),
      floatingActionButton:
          _isAdmin
              ? FloatingActionButton(
                onPressed: _showAddActivityDialog,
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
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              )
              : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshActivities,
          color: const Color(0xFF4CAF50),
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
                                    hintText: 'Search by name or description',
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
                                  onChanged: (_) => _filterActivities(),
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
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
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
                            child: StreamBuilder<List<Activity>>(
                              stream:
                                  _isAdmin
                                      ? _firestoreService.getAllActivities()
                                      : _firestoreService.getUserActivities(
                                        widget.currentUserId,
                                      ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapshot.hasError) {
                                  _logger.severe(
                                    'StreamBuilder error: ${snapshot.error}',
                                  );
                                  return Text(
                                    'Error: ${snapshot.error}',
                                    style: AppTypography.bodyText.copyWith(
                                      color: Colors.red,
                                    ),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  _logger.info(
                                    'No activities found in StreamBuilder',
                                  );
                                  return AnimationConfiguration.staggeredList(
                                    position: 0,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Center(
                                          child: Text(
                                            'No activities found',
                                            style: AppTypography.bodyText
                                                .copyWith(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                _filteredActivities = snapshot.data!;
                                if (_searchController.text.isNotEmpty) {
                                  final query =
                                      _searchController.text
                                          .trim()
                                          .toLowerCase();
                                  _filteredActivities =
                                      _filteredActivities.where((activity) {
                                        final nameMatch = activity.name
                                            .toLowerCase()
                                            .contains(query);
                                        final descriptionMatch = activity
                                            .description
                                            .toLowerCase()
                                            .contains(query);
                                        return nameMatch || descriptionMatch;
                                      }).toList();
                                }
                                _logger.info(
                                  'Loaded ${_filteredActivities.length} activities',
                                );
                                return ListView.builder(
                                  itemCount: _filteredActivities.length,
                                  itemBuilder: (context, index) {
                                    final activity = _filteredActivities[index];
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(
                                        milliseconds: 375,
                                      ),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: FutureBuilder<bool>(
                                            future: _firestoreService
                                                .isUserTeacherForActivity(
                                                  activity.id,
                                                  widget.currentUserId,
                                                ),
                                            builder: (context, snapshot) {
                                              final isTeacher =
                                                  snapshot.data ?? false;
                                              return ActivityCard(
                                                activity: activity,
                                                isAdmin: _isAdmin,
                                                isTeacher: isTeacher,
                                                currentUserId:
                                                    widget.currentUserId,
                                                onEdit:
                                                    () =>
                                                        _showEditActivityDialog(
                                                          activity,
                                                        ),
                                                onDelete:
                                                    () =>
                                                        _showDeleteActivityDialog(
                                                          activity,
                                                        ),
                                                onAssignStudents:
                                                    () =>
                                                        _showAssignStudentsDialog(
                                                          activity,
                                                        ),
                                                onViewDetails:
                                                    () => _showDetailsDialog(
                                                      activity,
                                                    ),
                                                onMarkRegister:
                                                    () =>
                                                        _showMarkRegisterDialog(
                                                          activity,
                                                        ),
                                                onViewRegisters:
                                                    () => _showRegisterList(
                                                      activity,
                                                    ),
                                              );
                                            },
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterActivities);
    _searchController.dispose();
    super.dispose();
    _logger.info('ActivityScreen disposed');
  }
}

class AddActivityDialog extends StatefulWidget {
  final Activity? activity;
  final Function(String name, String description, String teacherId)
  onAddActivity;

  const AddActivityDialog({
    super.key,
    this.activity,
    required this.onAddActivity,
  });

  @override
  _AddActivityDialogState createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<AddActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _teacherSearchController = TextEditingController();
  String? _selectedTeacherId;
  List<UserModel> _users = [];
  bool _isSubmitting = false;
  final Logger _logger = Logger('AddActivityDialog');

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _nameController.text = widget.activity!.name;
      _descriptionController.text = widget.activity!.description;
      _selectedTeacherId = widget.activity!.teacherId;
    }
    _teacherSearchController.addListener(_searchTeachers);
    _logger.info('AddActivityDialog initialized');
  }

  Future<void> _searchTeachers() async {
    final query = _teacherSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _users = [];
      });
      return;
    }
    try {
      final users = await FirestoreService().searchUsersByEmail(query);
      setState(() {
        _users = users;
      });
      _logger.info('Found ${users.length} users for query: $query');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error searching users: $e',
              style: AppTypography.bodyText,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      _logger.severe('Error searching users: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _teacherSearchController.removeListener(_searchTeachers);
    _teacherSearchController.dispose();
    super.dispose();
    _logger.info('AddActivityDialog disposed');
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
                    widget.activity == null ? 'Add Activity' : 'Edit Activity',
                    style: AppTypography.heading2.copyWith(
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Activity Name',
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
                        return 'Please enter an activity name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
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
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _teacherSearchController,
                    decoration: InputDecoration(
                      labelText: 'Search Teacher by Email',
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
                      if (_selectedTeacherId == null) {
                        return 'Please select a teacher';
                      }
                      return null;
                    },
                  ),
                  if (_users.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            title: Text(
                              user.email,
                              style: AppTypography.bodyText,
                            ),
                            subtitle: Text(
                              user.name ?? 'No name',
                              style: AppTypography.caption,
                            ),
                            onTap: () {
                              setState(() {
                                _selectedTeacherId = user.uid;
                                _teacherSearchController.text = user.email;
                                _users = [];
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
                        onTap:
                            _isSubmitting
                                ? null
                                : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() => _isSubmitting = true);
                                    await widget.onAddActivity(
                                      _nameController.text,
                                      _descriptionController.text,
                                      _selectedTeacherId!,
                                    );
                                    setState(() => _isSubmitting = false);
                                    Navigator.pop(context);
                                    _logger.info(
                                      'Activity submitted: ${_nameController.text}',
                                    );
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
                                    widget.activity == null
                                        ? 'Add Activity'
                                        : 'Save',
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

class AssignStudentsDialog extends StatefulWidget {
  final Activity activity;
  final Function(List<String> selectedStudentIds) onAssignStudents;

  const AssignStudentsDialog({
    super.key,
    required this.activity,
    required this.onAssignStudents,
  });

  @override
  _AssignStudentsDialogState createState() => _AssignStudentsDialogState();
}

class _AssignStudentsDialogState extends State<AssignStudentsDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<Student> _students = [];
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Logger _logger = Logger('AssignStudentsDialog');

  @override
  void initState() {
    super.initState();
    _selectedStudentIds = List.from(widget.activity.studentIds);
    _loadStudents();
    _searchController.addListener(_filterStudents);
    _logger.info(
      'AssignStudentsDialog initialized for activity: ${widget.activity.name}',
    );
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
        _isLoading = false;
      });
      _logger.info('Loaded ${students.length} students');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
      _logger.severe('Error loading students: $e');
    }
  }

  void _filterStudents() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _students =
          _students.where((student) {
            final nameMatch = student.name.toLowerCase().contains(query);
            final classMatch = student.className.toLowerCase().contains(query);
            return nameMatch || classMatch;
          }).toList();
    });
    _logger.info('Filtered students count: ${_students.length}');
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStudents);
    _searchController.dispose();
    super.dispose();
    _logger.info('AssignStudentsDialog disposed');
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
                  'Assign Students to ${widget.activity.name}',
                  style: AppTypography.heading2.copyWith(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Students',
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
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodyText.copyWith(color: Colors.red),
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
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
                            value: _selectedStudentIds.contains(student.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudentIds.add(student.id);
                                } else {
                                  _selectedStudentIds.remove(student.id);
                                }
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
                        widget.onAssignStudents(_selectedStudentIds);
                        Navigator.pop(context);
                        _logger.info(
                          'Assigned ${_selectedStudentIds.length} students',
                        );
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
                          'Assign',
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

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final bool isAdmin;
  final bool isTeacher;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssignStudents;
  final VoidCallback onViewDetails;
  final VoidCallback onMarkRegister;
  final VoidCallback onViewRegisters;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.isAdmin,
    required this.isTeacher,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
    required this.onAssignStudents,
    required this.onViewDetails,
    required this.onMarkRegister,
    required this.onViewRegisters,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF4CAF50),
                    child: Text(
                      activity.name.substring(0, 1).toUpperCase(),
                      style: AppTypography.bodyText.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: AppTypography.bodyText.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activity.description,
                          style: AppTypography.caption.copyWith(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<UserModel?>(
                          future: FirestoreService().getUser(
                            activity.teacherId,
                          ),
                          builder: (context, snapshot) {
                            String teacherName = 'Unknown';
                            if (snapshot.hasData && snapshot.data != null) {
                              teacherName =
                                  snapshot.data!.name ??
                                  snapshot.data!.email.split('@')[0];
                            }
                            return Text(
                              'Teacher: $teacherName',
                              style: AppTypography.caption.copyWith(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isAdmin) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info, color: Colors.blue),
                      onPressed: onViewDetails,
                      tooltip: 'View Details',
                    ),
                    IconButton(
                      icon: const Icon(Icons.group_add, color: Colors.green),
                      onPressed: onAssignStudents,
                      tooltip: 'Assign Students',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: onEdit,
                      tooltip: 'Edit Activity',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete Activity',
                    ),
                    IconButton(
                      icon: const Icon(Icons.list, color: Colors.blue),
                      onPressed: onViewRegisters,
                      tooltip: 'View Registers',
                    ),
                  ],
                ),
              ] else if (isTeacher) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: onMarkRegister,
                      tooltip: 'Mark Register',
                    ),
                    IconButton(
                      icon: const Icon(Icons.list, color: Colors.blue),
                      onPressed: onViewRegisters,
                      tooltip: 'View Registers',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// [Existing code remains unchanged until GenerateReportDialog class]

// Replace the entire GenerateReportDialog class with the following:

class GenerateReportDialog extends StatefulWidget {
  final List<Activity> activities;
  final Function(String type, String? id, String name) onGenerateReport;

  const GenerateReportDialog({
    super.key,
    required this.activities,
    required this.onGenerateReport,
  });

  @override
  _GenerateReportDialogState createState() => _GenerateReportDialogState();
}

class _GenerateReportDialogState extends State<GenerateReportDialog> {
  final FirestoreService _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _reportType = 'all';
  String? _selectedId;
  String? _selectedName;
  List<UserModel> _teachers = [];
  List<Student> _students = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Logger _logger = Logger('GenerateReportDialog');

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.activities;
    _searchController.addListener(_filterItems);
    _logger.info('GenerateReportDialog initialized');
  }

  void _filterItems() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (_reportType == 'single') {
        _filteredItems =
            widget.activities.where((activity) {
              return activity.name.toLowerCase().contains(query);
            }).toList();
      } else if (_reportType == 'teacher') {
        _filteredItems =
            _teachers.where((teacher) {
              final nameMatch =
                  teacher.name?.toLowerCase().contains(query) ?? false;
              final emailMatch = teacher.email.toLowerCase().contains(query);
              return nameMatch || emailMatch;
            }).toList();
      } else if (_reportType == 'student') {
        _filteredItems =
            _students.where((student) {
              final nameMatch = student.name.toLowerCase().contains(query);
              final classMatch = student.className.toLowerCase().contains(
                query,
              );
              return nameMatch || classMatch;
            }).toList();
      } else if (_reportType == 'all_registers') {
        _filteredItems =
            widget.activities.where((activity) {
              return activity.name.toLowerCase().contains(query);
            }).toList();
      }
    });
    _logger.info(
      'Filtered items count: ${_filteredItems.length} for type: $_reportType',
    );
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _firestoreService.getAllUsers();
      setState(() {
        _teachers = users.where((user) => user.role == 'teacher').toList();
        _filteredItems = _teachers;
        _isLoading = false;
      });
      _logger.info('Loaded ${_teachers.length} teachers');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading teachers: $e';
        _isLoading = false;
      });
      _logger.severe('Error loading teachers: $e');
    }
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
        _filteredItems = _students;
        _isLoading = false;
      });
      _logger.info('Loaded ${_students.length} students');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading students: $e';
        _isLoading = false;
      });
      _logger.severe('Error loading students: $e');
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
    _logger.info('GenerateReportDialog disposed');
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
                  'Generate Activity Report',
                  style: AppTypography.heading2.copyWith(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _reportType,
                  decoration: InputDecoration(
                    labelText: 'Report Type',
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
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(
                        'All Activities',
                        style: AppTypography.bodyText,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'single',
                      child: Text(
                        'Single Activity',
                        style: AppTypography.bodyText,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'teacher',
                      child: Text('By Teacher', style: AppTypography.bodyText),
                    ),
                    DropdownMenuItem(
                      value: 'student',
                      child: Text('By Student', style: AppTypography.bodyText),
                    ),
                    DropdownMenuItem(
                      value: 'all_registers',
                      child: Text(
                        'All Registers',
                        style: AppTypography.bodyText,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'single_register',
                      child: Text(
                        'Single Register',
                        style: AppTypography.bodyText,
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    setState(() {
                      _reportType = value!;
                      _selectedId = null;
                      _selectedName = null;
                      _filteredItems = widget.activities;
                      _searchController.clear();
                    });
                    if (value == 'teacher') {
                      await _loadTeachers();
                    } else if (value == 'student') {
                      await _loadStudents();
                    } else if (value == 'single_register') {
                      await _loadStudents();
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (_reportType != 'all' && _reportType != 'all_registers')
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText:
                          _reportType == 'single'
                              ? 'Search Activity'
                              : _reportType == 'teacher'
                              ? 'Search Teacher by Email'
                              : _reportType == 'student'
                              ? 'Search Student'
                              : 'Search Student',
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
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.bodyText.copyWith(color: Colors.red),
                    ),
                  ),
                if (_reportType != 'all' &&
                    _reportType != 'all_registers' &&
                    !_isLoading)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        String title = '';
                        String subtitle = '';
                        String id = '';
                        if (_reportType == 'single') {
                          title = (item as Activity).name;
                          subtitle = item.description;
                          id = item.id;
                        } else if (_reportType == 'teacher') {
                          title = (item as UserModel).email;
                          subtitle = item.name ?? 'No name';
                          id = item.uid;
                        } else if (_reportType == 'student' ||
                            _reportType == 'single_register') {
                          title = (item as Student).name;
                          subtitle = item.className;
                          id = item.id;
                        }
                        return ListTile(
                          title: Text(title, style: AppTypography.bodyText),
                          subtitle: Text(
                            subtitle,
                            style: AppTypography.caption,
                          ),
                          onTap: () {
                            setState(() {
                              _selectedId = id;
                              _selectedName = title;
                              _searchController.text = title;
                              _filteredItems = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
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
                          (_selectedId == null &&
                                      (_reportType == 'single' ||
                                          _reportType == 'teacher' ||
                                          _reportType == 'student' ||
                                          _reportType == 'single_register')) ||
                                  _isLoading
                              ? null
                              : () {
                                widget.onGenerateReport(
                                  _reportType,
                                  _selectedId,
                                  _selectedName ?? 'All Activities',
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
                          'Generate and Share',
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

// [Rest of the file remains unchanged]
