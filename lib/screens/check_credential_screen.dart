import 'package:certiverify/screens/certificate_details_screen.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class CheckCredentialScreen extends StatefulWidget {
  final String? initialCredentialId;

  const CheckCredentialScreen({super.key, this.initialCredentialId});

  @override
  State<CheckCredentialScreen> createState() => _CheckCredentialScreenState();
}

class _CheckCredentialScreenState extends State<CheckCredentialScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _credentialIdController = TextEditingController();

  bool _isLoading = false;
  bool _hasChecked = false;
  Map<String, dynamic>? _result;
  String? _error;

  get certificate => null;

  @override
  void initState() {
    super.initState();
    if (widget.initialCredentialId != null) {
      _credentialIdController.text = widget.initialCredentialId!;
      _checkCredential();
    }
  }

  @override
  void dispose() {
    _credentialIdController.dispose();
    super.dispose();
  }

  Future<void> _checkCredential() async {
    final credentialId = _credentialIdController.text.trim();

    if (credentialId.isEmpty) {
      setState(() {
        _error = 'Please enter a Credential ID';
        _hasChecked = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasChecked = false;
      _error = null;
    });

    final result = await _apiService.checkCredentialStatus(credentialId);

    setState(() {
      _isLoading = false;
      _hasChecked = true;

      if (result['success']) {
        _result = result;
        _error = null;
      } else {
        _error = result['error'];
        _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Credential')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter Credential ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _credentialIdController,
                      decoration: InputDecoration(
                        hintText: 'e.g. 3c05039a-950a-4259-b9af-b610dc7ad552',
                        prefixIcon: const Icon(Icons.verified_user),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (_) => _checkCredential(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkCredential,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify Credential'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Result section
            if (_hasChecked) _buildResultCard(),

            // Info section
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can find the Credential ID on the issued certificate or scan the QR code.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
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

  Widget _buildResultCard() {
    final bool isValid = _result?['isValid'] ?? false;
    final status = _result?['status'] ?? 'unknown';
    final checkedAt = _result?['checkedAt'] ?? '';
    final credentialId = _result?['credentialId'] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isValid ? AppTheme.secondary : AppTheme.error,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: (isValid ? AppTheme.secondary : AppTheme.error)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isValid ? Icons.check_circle : Icons.cancel,
                  size: 48,
                  color: isValid ? AppTheme.secondary : AppTheme.error,
                ),
              ),
              const SizedBox(height: 16),

              // Status Text
              Text(
                isValid ? 'CERTIFICATE VALID' : 'CERTIFICATE INVALID',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isValid ? AppTheme.secondary : AppTheme.error,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isValid
                    ? 'This credential is active and verified'
                    : 'This credential is not valid',
                style: TextStyle(
                  fontSize: 14,
                  color: isValid ? AppTheme.secondary : AppTheme.error,
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Details
              _buildDetailRow(
                icon: Icons.qr_code,
                label: 'Credential ID',
                value: credentialId,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.verified,
                label: 'Status',
                value: status.toUpperCase(),
                valueColor: isValid ? AppTheme.secondary : AppTheme.error,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                icon: Icons.access_time,
                label: 'Checked At',
                value: _formatDateTime(checkedAt),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              if (isValid)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to full certificate details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CredentialDetailsScreen(
                            credentialId: credentialId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Full Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              if (!isValid && status != 'active') const SizedBox(height: 8),

              if (!isValid && status != 'active')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 20, color: AppTheme.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status == 'revoked'
                              ? 'This certificate has been revoked by the issuing institution.'
                              : 'This credential could not be found in the blockchain registry.',
                          style: TextStyle(fontSize: 13, color: AppTheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 12),
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor,
              fontFamily: label == 'Credential ID' ? 'monospace' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final localDate = date.toLocal();
      return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
          '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}:${localDate.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
}
