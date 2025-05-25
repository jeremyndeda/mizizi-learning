import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class GenerateRequestReportScreen extends StatefulWidget {
  const GenerateRequestReportScreen({super.key});

  @override
  _GenerateRequestReportScreenState createState() =>
      _GenerateRequestReportScreenState();
}

class _GenerateRequestReportScreenState
    extends State<GenerateRequestReportScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _status;
  String? _requesterEmail;
  final _requesterEmailController = TextEditingController();
  final PdfService _pdfService = PdfService();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _generatePdf() async {
    if (_startDate != null && _endDate == null ||
        _startDate == null && _endDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates or neither'),
        ),
      );
      return;
    }
    if (_requesterEmail != null && _requesterEmail!.isNotEmpty) {
      final user = await _firestoreService.getUserByEmail(_requesterEmail!);
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }
    }
    final file = await _pdfService.generateRequestsReport(
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      requesterEmail: _requesterEmail,
    );
    Share.shareXFiles([XFile(file.path)], text: 'Item Requests Report');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate Request Report',
          style: AppTypography.heading2,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomButton(
              text:
                  _startDate == null
                      ? 'Select Start Date'
                      : _startDate!.toString().split(' ')[0],
              onPressed: _selectStartDate,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text:
                  _endDate == null
                      ? 'Select End Date'
                      : _endDate!.toString().split(' ')[0],
              onPressed: _selectEndDate,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: const TextStyle(color: AppColors.primaryGreen),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  ['All', 'Pending', 'Approved', 'Rejected'].map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _status = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _requesterEmailController,
              labelText: 'Requester Email',
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  _requesterEmail = value.trim();
                });
              },
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Generate PDF', onPressed: _generatePdf),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _requesterEmailController.dispose();
    super.dispose();
  }
}
