import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final ApiService _apiService = ApiService();

  String _selectedInstitutionCode = 'UNILAG';
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

  // Generate a digital signature (in production, this would be cryptographic)
  String _generateDigitalSignature() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'sig_${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _degreeController.dispose();
    super.dispose();
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
    if (result['qrCodeBase64'] != null) {
      qrBytes = base64Decode(result['qrCodeBase64']);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.secondary, size: 28),
            SizedBox(width: 12),
            Text('Certificate Issued Successfully!'),
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

              // QR Code
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
                          'Scan to Verify',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
                    _buildDetailRow(
                      label: 'Credential ID',
                      value: result['credentialId'],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      label: 'Transaction ID',
                      value: result['transactionId'],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      label: 'Issued By',
                      value: result['issuedBy'],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      label: 'Issued At',
                      value: _formatDate(result['issuedAt']),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Verification URL
              if (result['verificationUrl'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result['verificationUrl']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.primary,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
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

  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
      body: SafeArea(
        child: SingleChildScrollView(
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

                // Student ID (Matric Number)
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID / Matric Number *',
                    prefixIcon: Icon(Icons.numbers),
                    hintText: 'e.g. CSC/20/4835',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter student ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Student Full Name
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

                // Institution Code (Dropdown) - FIXED: Added proper width constraints
                Container(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: DropdownButtonFormField<String>(
                    value: _selectedInstitutionCode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Institution *',
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: _institutions.map((inst) {
                      return DropdownMenuItem(
                        value: inst['code'],
                        child: Text(
                          inst['name']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedInstitutionCode = value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select institution';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Degree
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(
                    labelText: 'Degree *',
                    prefixIcon: Icon(Icons.school),
                    hintText: 'e.g. B.Sc. Computer Science',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter degree';
                    }
                    return null;
                  },
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

                // Blockchain Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      const Expanded(
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
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
      ),
    );
  }
}
