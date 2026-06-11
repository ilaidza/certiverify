// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';

class IssueCertificateScreen extends StatefulWidget {
  const IssueCertificateScreen({super.key});

  @override
  State<IssueCertificateScreen> createState() => _IssueCertificateScreenState();
}

class _IssueCertificateScreenState extends State<IssueCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _studentNameController = TextEditingController();
  final _degreeController = TextEditingController();
  final _cgpaController = TextEditingController();

  final ApiService _apiService = ApiService();

  String _selectedInstitutionCode = 'FUTA';
  DateTime? _graduationDate;
  bool _isSubmitting = false;

  // List of Nigerian institutions with their codes
  final List<Map<String, String>> _institutions = [
    {'code': 'UNILAG', 'name': 'University of Lagos'},
    {'code': 'UNN', 'name': 'University of Nigeria, Nsukka'},
    {'code': 'OAU', 'name': 'Obafemi Awolowo University'},
    {'code': 'ABU', 'name': 'Ahmadu Bello University'},
    {'code': 'UI', 'name': 'University of Ibadan'},
    {'code': 'FUTA', 'name': 'Federal University of Technology, Akure'},
    {'code': 'UNIBEN', 'name': 'University of Benin'},
    {'code': 'UNIMAID', 'name': 'University of Maiduguri'},
    {'code': 'FUNAAB', 'name': 'Federal University of Agriculture, Abeokuta'},
    {'code': 'COVENANT', 'name': 'Covenant University'},
  ];

  // Generate a digital signature
  String _generateDigitalSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sig_${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _degreeController.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  void _fillTestData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(8);
    setState(() {
      _studentIdController.text = 'STU${timestamp}';
      _studentNameController.text = 'John Doe';
      _degreeController.text = 'Bachelor of Science in Computer Science';
      _cgpaController.text = '4.5';
      _graduationDate = DateTime(2024, 12, 15);
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _graduationDate = date);
    }
  }

  Future<void> _shareQRCode(Uint8List qrBytes, String studentName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/certificate_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(qrBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Certificate QR Code for $studentName - Verify at CredChain Nigeria',
      );
    } catch (e) {
      print('Error sharing QR code: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share QR code')),
        );
      }
    }
  }

  Future<void> _submitCertificate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_graduationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select graduation date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _apiService.issueCertificate(
      studentId: _studentIdController.text.trim(),
      studentName: _studentNameController.text.trim(),
      institutionCode: _selectedInstitutionCode,
      degree: _degreeController.text.trim(),
      graduationDate: _graduationDate!.toIso8601String().split('T')[0],
      issuerDigitalSignature: _generateDigitalSignature(),
      cgpa: _cgpaController.text.trim().isNotEmpty
          ? _cgpaController.text.trim()
          : null,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] && mounted) {
      // await NotificationService.showCertificateIssued(
      //   studentName: _studentNameController.text.trim(),
      //   degree: _degreeController.text.trim(),
      // );

      await _showSuccessDialog(result);
      _clearForm();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Failed to issue certificate'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(Map<String, dynamic> result) async {
    Uint8List? qrBytes;
    if (result['qrCodeBase64'] != null &&
        result['qrCodeBase64'].toString().isNotEmpty) {
      try {
        qrBytes = base64Decode(result['qrCodeBase64']);
        print('QR Code decoded successfully, size: ${qrBytes.length} bytes');
      } catch (e) {
        print('Error decoding QR code: $e');
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.secondary, size: 28),
            SizedBox(width: 10),
            Text(
              'Certificate Issued Successfully!',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_studentNameController.text.trim()} has been issued their certificate.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),

              // QR Code Display
              if (qrBytes != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.outlineVariant,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.memory(qrBytes, width: 180, height: 180),
                        const SizedBox(height: 12),
                        Text(
                          'Scan QR Code to Verify',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Share this QR code with employers',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, size: 20, color: AppTheme.error),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'QR code not available. You can still verify using the Credential ID.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Credential Details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Credential ID', result['credentialId']),
                    const SizedBox(height: 8),
                    _buildDetailRow('Transaction ID', result['transactionId']),
                    const SizedBox(height: 8),
                    _buildDetailRow('Issued By', result['issuedBy']),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Issued At',
                      _formatDate(result['issuedAt']),
                    ),
                    if (result['studentId'] != null)
                      _buildDetailRow('Student ID', result['studentId']),
                    if (result['degree'] != null)
                      _buildDetailRow('Degree', result['degree']),
                    if (result['graduationDate'] != null)
                      _buildDetailRow(
                        'Graduation Date',
                        _formatDate(result['graduationDate']),
                      ),
                    if (_cgpaController.text.trim().isNotEmpty)
                      _buildDetailRow('CGPA', _cgpaController.text.trim()),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Share Button
              if (qrBytes != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareQRCode(
                      qrBytes!,
                      _studentNameController.text.trim(),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share QR Code'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            child: const Text('Issue Another'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.dashboard, size: 18),
            label: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  void _clearForm() {
    _studentIdController.clear();
    _studentNameController.clear();
    _degreeController.clear();
    _cgpaController.clear();
    _graduationDate = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final institutionName =
        authProvider.currentUser?.institutionName ?? 'Your Institution';

    return Scaffold(
      appBar: AppBar(title: const Text('Issue Credential')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Institution card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Issuing Institution',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            institutionName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Student ID
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID / Matric Number *',
                  prefixIcon: Icon(Icons.numbers),
                  hintText: 'e.g. STU12345, CSC/20/4835',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Student Name
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name *',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'e.g. John Doe',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter student name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Institution Code
              DropdownButtonFormField<String>(
                value: _selectedInstitutionCode,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Institution *',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _institutions.map((inst) {
                  return DropdownMenuItem(
                    value: inst['code'],
                    child: Text(inst['name']!),
                  );
                }).toList(),
                onChanged: (value) =>
                    setState(() => _selectedInstitutionCode = value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select institution';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Degree
              TextFormField(
                controller: _degreeController,
                decoration: const InputDecoration(
                  labelText: 'Degree *',
                  prefixIcon: Icon(Icons.school),
                  hintText: 'e.g. Bachelor of Science in Computer Science',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter degree';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CGPA
              TextFormField(
                controller: _cgpaController,
                decoration: const InputDecoration(
                  labelText: 'CGPA',
                  prefixIcon: Icon(Icons.calculate),
                  hintText: 'e.g. 4.5',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Graduation Date
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _graduationDate != null
                          ? '${_graduationDate!.year}-${_graduationDate!.month.toString().padLeft(2, '0')}-${_graduationDate!.day.toString().padLeft(2, '0')}'
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Graduation Date *',
                      prefixIcon: Icon(Icons.calendar_today),
                      hintText: 'Select date',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Test Data Button
              OutlinedButton.icon(
                onPressed: _fillTestData,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Fill Test Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Blockchain Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield, color: AppTheme.primary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Immutable Security',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This certificate will be recorded on the blockchain with a unique cryptographic hash.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCertificate,
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Issuing to Blockchain...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_moderator),
                            SizedBox(width: 8),
                            Text('Issue Certificate'),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
