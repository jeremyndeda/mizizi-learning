import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class ReportFilterDialog extends StatefulWidget {
  final String currentUserId;

  const ReportFilterDialog({super.key, required this.currentUserId});

  @override
  _ReportFilterDialogState createState() => _ReportFilterDialogState();
}

class _ReportFilterDialogState extends State<ReportFilterDialog> {
  String _filterType = 'All';
  DateTimeRange? _dateRange;
  DateTime? _specificDate;
  String? _userEmail;
  final _userEmailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _specificDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Generate PDF Report', style: AppTypography.heading2),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _filterType,
              decoration: InputDecoration(
                labelText: 'Report Type',
                labelStyle: const TextStyle(color: AppColors.primaryGreen),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  ['All', 'Date Range', 'Single Day', 'By User'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  _filterType = value!;
                  _dateRange = null;
                  _specificDate = null;
                  _userEmail = null;
                  _userEmailController.clear();
                });
              },
            ),
            if (_filterType == 'Date Range') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickDateRange,
                child: Text(
                  _dateRange == null
                      ? 'Select Date Range'
                      : '${_dateRange!.start.toString().split(' ')[0]} to ${_dateRange!.end.toString().split(' ')[0]}',
                ),
              ),
            ],
            if (_filterType == 'Single Day') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickDate,
                child: Text(
                  _specificDate == null
                      ? 'Select Date'
                      : _specificDate!.toString().split(' ')[0],
                ),
              ),
            ],
            if (_filterType == 'By User') ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _userEmailController,
                labelText: 'User Email',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: 'Generate',
          onPressed: () async {
            if (_filterType == 'Date Range' && _dateRange == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a date range')),
              );
              return;
            }
            if (_filterType == 'Single Day' && _specificDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a date')),
              );
              return;
            }
            if (_filterType == 'By User' && _userEmailController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a user email')),
              );
              return;
            }

            if (_filterType == 'By User') {
              final user = await _firestoreService.getUserByEmail(
                _userEmailController.text.trim(),
              );
              if (user == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('User not found')));
                return;
              }
              _userEmail = user.uid;
            }

            Navigator.pop(context, {
              'filterType': _filterType,
              'dateRange': _dateRange,
              'specificDate': _specificDate,
              'userId': _userEmail,
              'userName': _userEmailController.text.trim(),
            });
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _userEmailController.dispose();
    super.dispose();
  }
}
