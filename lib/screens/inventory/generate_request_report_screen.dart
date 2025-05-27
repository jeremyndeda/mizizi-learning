import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/widgets/custom_button.dart';

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
  String? _status = 'All';
  final TextEditingController _requesterEmailController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final PdfService _pdfService = PdfService();
  final FirestoreService _firestoreService = FirestoreService();

  List<String> _allEmails = [];
  List<String> _suggestedEmails = [];
  Timer? _debounce;
  final GlobalKey<State<StatefulWidget>> _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _fetchEmails();

    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        _updateSuggestions(_requesterEmailController.text);
      } else {
        setState(() => _suggestedEmails.clear());
        _hideSuggestions();
      }
    });

    _requesterEmailController.addListener(() {
      _updateSuggestions(_requesterEmailController.text);
    });
  }

  Future<void> _fetchEmails() async {
    final emails = await _firestoreService.getAllUserEmails();
    setState(() {
      _allEmails = emails;
    });
  }

  void _updateSuggestions(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final input = value.trim().toLowerCase();
      setState(() {
        if (input.isEmpty) {
          _suggestedEmails = _allEmails.take(10).toList();
        } else {
          _suggestedEmails =
              _allEmails
                  .where((email) => email.toLowerCase().contains(input))
                  .take(10)
                  .toList();
        }
      });
      if (_suggestedEmails.isNotEmpty) {
        _showSuggestions();
      } else {
        _hideSuggestions();
      }
    });
  }

  void _showSuggestions() {
    if (_overlayEntry != null) return;
    final context = _textFieldKey.currentContext;
    if (context == null) return;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 8,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children:
                      _suggestedEmails
                          .asMap()
                          .entries
                          .map(
                            (entry) => ListTile(
                              key: ValueKey(entry.key),
                              title: Text(entry.value),
                              onTap: () {
                                _selectEmail(entry.value);
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: AppColors.white,
                              textColor: AppColors.primaryGreen,
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void _selectEmail(String email) {
    setState(() {
      _requesterEmailController.text = email;
      _suggestedEmails.clear();
    });
    _hideSuggestions();
    _emailFocusNode.unfocus();
  }

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
    if ((_startDate != null && _endDate == null) ||
        (_startDate == null && _endDate != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates or neither'),
        ),
      );
      return;
    }

    final emailInput = _requesterEmailController.text.trim().toLowerCase();
    if (emailInput.isNotEmpty) {
      final user = await _firestoreService.getUserByEmail(emailInput);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requester email not found')),
        );
        return;
      }
    }

    final file = await _pdfService.generateRequestsReport(
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      requesterEmail: emailInput.isEmpty ? null : emailInput,
    );

    if (file.lengthSync() == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching requests found for the selected filters'),
        ),
      );
      return;
    }

    Share.shareXFiles([XFile(file.path)], text: 'Item Requests Report');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _suggestedEmails.clear());
        _hideSuggestions();
      },
      child: Scaffold(
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
                        : _startDate!.toIso8601String().split('T')[0],
                onPressed: _selectStartDate,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text:
                    _endDate == null
                        ? 'Select End Date'
                        : _endDate!.toIso8601String().split('T')[0],
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
                    ['All', 'Pending', 'Approved', 'Rejected']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 16),
              TextField(
                key: _textFieldKey,
                focusNode: _emailFocusNode,
                controller: _requesterEmailController,
                decoration: InputDecoration(
                  labelText: 'Requester Email',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Generate PDF', onPressed: _generatePdf),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _requesterEmailController.dispose();
    _emailFocusNode.dispose();
    _debounce?.cancel();
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    super.dispose();
  }
}
