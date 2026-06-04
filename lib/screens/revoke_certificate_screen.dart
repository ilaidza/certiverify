import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class RevokeCertificateScreen extends StatefulWidget {
  final String? initialCredentialId;

  const RevokeCertificateScreen({super.key, this.initialCredentialId});

  @override
  State<RevokeCertificateScreen> createState() =>
      _RevokeCertificateScreenState();
}

class _RevokeCertificateScreenState extends State<RevokeCertificateScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _credentialIdController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isLoading = false;
  bool _isRevoking = false;
  Map<String, dynamic>? _certificateInfo;
  String? _error;
  Map<String, dynamic>? _revokeResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialCredentialId != null) {
      _credentialIdController.text = widget.initialCredentialId!;
      _fetchCertificateInfo();
    }
  }

  @override
  void dispose() {
    _credentialIdController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchCertificateInfo() async {
    final credentialId = _credentialIdController.text.trim();

    if (credentialId.isEmpty) {
      setState(() {
        _error = 'Please enter a Credential ID';
        _certificateInfo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _certificateInfo = null;
      _revokeResult = null;
    });

    final result = await _apiService.checkCredentialStatus(credentialId);

    setState(() {
      _isLoading = false;

      if (result['success']) {
        _certificateInfo = result;
        if (result['status'] != 'active') {
          _error = 'This credential is already ${result['status']}';
        }
      } else {
        _error = result['error'];
      }
    });
  }

  Future<void> _revokeCertificate() async {
    final credentialId = _credentialIdController.text.trim();
    final reason = _reasonController.text.trim();

    if (credentialId.isEmpty) {
      setState(() {
        _error = 'Please enter a Credential ID';
      });
      return;
    }

    if (reason.isEmpty) {
      setState(() {
        _error = 'Please provide a reason for revocation';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Certificate'),
        content: Text(
          'Are you sure you want to revoke this certificate?\n\n'
          'Credential ID: $credentialId\n'
          'Reason: $reason\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRevoking = true;
      _error = null;
    });

    final result = await _apiService.revokeCredential(
      credentialId: credentialId,
      reason: reason,
    );

    setState(() {
      _isRevoking = false;

      if (result['success']) {
        _revokeResult = result;
        _certificateInfo = null;
        _reasonController.clear();
      } else {
        _error = result['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isInstitutionAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revoke Certificate')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 80, color: AppTheme.error),
                SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Only Institution Admins can revoke certificates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revoke Certificate'),
        backgroundColor: AppTheme.error,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error, width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, size: 28, color: AppTheme.error),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Warning: Revoking a certificate is permanent and cannot be undone.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Credential ID Input
            const Text(
              'Credential ID',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Input row without Row widget - use Column for simpler layout
            TextField(
              controller: _credentialIdController,
              decoration: InputDecoration(
                hintText: 'e.g. 3c05039a-950a-4259-b9af-b610dc7ad552',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Check button - full width
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _fetchCertificateInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Check Credential'),
              ),
            ),

            const SizedBox(height: 16),

            // Certificate Info
            if (_certificateInfo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 20,
                          color: AppTheme.secondary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Certificate Information',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Status',
                      _certificateInfo!['status']?.toUpperCase() ?? 'UNKNOWN',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Checked At',
                      _formatDateTime(_certificateInfo!['checkedAt'] ?? ''),
                    ),
                  ],
                ),
              ),

            // Error Message
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, size: 20, color: AppTheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Reason Input
            if (_certificateInfo != null &&
                _certificateInfo!['status'] == 'active')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revocation Reason',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Academic dishonesty, Administrative error',
                      prefixIcon: const Icon(Icons.comment),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Revoke Button
            if (_certificateInfo != null &&
                _certificateInfo!['status'] == 'active')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRevoking ? null : _revokeCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: _isRevoking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Revoke Certificate'),
                ),
              ),

            // Success Result
            if (_revokeResult != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.secondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.secondary),
                        SizedBox(width: 8),
                        Text(
                          'Revocation Successful',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Credential ID',
                      _revokeResult!['credentialId'],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Reason', _revokeResult!['reason']),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Revoked At',
                      _formatDateTime(_revokeResult!['revokedAt']),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow('Revoked By', _revokeResult!['revokedBy']),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _revokeResult = null;
                            _certificateInfo = null;
                            _credentialIdController.clear();
                            _reasonController.clear();
                          });
                        },
                        child: const Text('Revoke Another'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    if (isoString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(isoString);
      final localDate = date.toLocal();
      return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
          '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
