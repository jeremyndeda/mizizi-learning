// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';

import '../../core/constants/typography.dart';
import '../../core/models/activity.dart';
import '../../core/models/activity_register.dart';
import '../../core/models/student.dart';
import '../../core/services/firestore_service.dart';

class RegisterListScreen extends StatefulWidget {
  final Activity activity;

  const RegisterListScreen({super.key, required this.activity});

  @override
  State<RegisterListScreen> createState() => _RegisterListScreenState();
}

class _RegisterListScreenState extends State<RegisterListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  /// Registers grouped by calendar day.
  Map<DateTime, List<ActivityRegister>> _registersByDate = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRegisters();
  }

  Future<void> _loadRegisters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registers =
          await _firestoreService
              .getActivityRegisters(widget.activity.id)
              .first;

      final Map<DateTime, List<ActivityRegister>> grouped = {};
      for (final r in registers) {
        final dateOnly = DateTime(r.date.year, r.date.month, r.date.day);
        grouped.putIfAbsent(dateOnly, () => []).add(r);
      }

      setState(() {
        _registersByDate = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading registers: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                )
                : _errorMessage != null
                ? Center(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodyText.copyWith(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
                : _registersByDate.isEmpty
                ? _buildEmptyState()
                : _buildRegisterList(),
      ),
    );
  }

  /* --------------------------  UI helpers -------------------------- */

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '${widget.activity.name} Registers',
        style: AppTypography.heading1.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimationLimiter(
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 500),
        child: SlideAnimation(
          verticalOffset: 50,
          child: FadeInAnimation(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No registers found for ${widget.activity.name}',
                    style: AppTypography.bodyText.copyWith(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try marking attendance to create a register.',
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterList() {
    final dates =
        _registersByDate.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // recent first

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: dates.length,
          itemBuilder: (context, listIndex) {
            final date = dates[listIndex];
            final regs = _registersByDate[date]!;

            return _buildDateCard(date, regs, listIndex);
          },
        ),
      ),
    );
  }

  Widget _buildDateCard(
    DateTime date,
    List<ActivityRegister> regs,
    int listIndex,
  ) {
    return AnimationConfiguration.staggeredList(
      position: listIndex,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF4CAF50),
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  DateFormat('MMMM d, yyyy').format(date),
                  style: AppTypography.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  '${regs.length} Register${regs.length > 1 ? 's' : ''}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                children:
                    regs
                        .asMap()
                        .entries
                        .map((e) => _buildSingleRegisterTile(e.key, e.value))
                        .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleRegisterTile(
    int registerIndex,
    ActivityRegister register,
  ) {
    return FutureBuilder<List<Student>>(
      future: _firestoreService.getAllStudents().first,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Error: ${snap.error}',
              style: AppTypography.bodyText.copyWith(color: Colors.red),
            ),
          );
        }

        final students =
            snap.data!
                .where((s) => register.attendance.containsKey(s.id))
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (registerIndex > 0)
              const Divider(height: 1, thickness: 1, color: Colors.grey),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Register ${registerIndex + 1} – '
                '${DateFormat('hh:mm a').format(register.date)}',
                style: AppTypography.bodyText.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            ...students.map((student) {
              final present = register.attendance[student.id] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        present
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE57373),
                    child: Icon(
                      present ? Icons.check : Icons.clear,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: AppTypography.bodyText.copyWith(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    student.className,
                    style: AppTypography.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Text(
                    present ? 'Present' : 'Absent',
                    style: AppTypography.caption.copyWith(
                      color:
                          present
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFE57373),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
