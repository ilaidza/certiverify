import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class GraduateCredentialDetailScreen extends StatefulWidget {
  final String credentialId;

  const GraduateCredentialDetailScreen({super.key, required this.credentialId});

  @override
  State<GraduateCredentialDetailScreen> createState() =>
      _GraduateCredentialDetailScreenState();
}

class _GraduateCredentialDetailScreenState
    extends State<GraduateCredentialDetailScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _credential;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCredentialDetails();
  }

  Future<void> _fetchCredentialDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _apiService.getGraduateCredential(widget.credentialId);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _credential = result;
      } else {
        _error = result['error'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _credential?['isValid'] ?? false;
    final status = _credential?['status'] ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCredentialDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(_error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCredentialDetails,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isActive ? AppTheme.secondary : AppTheme.error)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isActive ? Icons.verified : Icons.cancel,
                          size: 80,
                          color: isActive ? AppTheme.secondary : AppTheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isActive
                              ? 'VALID CERTIFICATE'
                              : 'INVALID CERTIFICATE',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AppTheme.secondary
                                : AppTheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isActive
                              ? 'This certificate is active and verified'
                              : status == 'revoked'
                              ? 'This certificate has been revoked'
                              : 'This certificate is not valid',
                          style: TextStyle(
                            fontSize: 14,
                            color: isActive
                                ? AppTheme.secondary
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Certificate Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'CERTIFICATE INFORMATION',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDetailRow(
                          'Credential ID',
                          _credential?['credentialId'] ?? widget.credentialId,
                          isMonospace: true,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow('Status', status.toUpperCase()),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Issued At',
                          _formatDateTime(_credential?['issuedAt'] ?? ''),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Last Checked',
                          _formatDateTime(_credential?['checkedAt'] ?? ''),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: 20,
                                color: AppTheme.primary,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This certificate is verified on the CredChain Blockchain Network',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Warning if revoked
                  if (!isActive && status == 'revoked')
                    Container(
                      padding: const EdgeInsets.all(12),
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
                              'This certificate has been revoked by the issuing institution and is no longer valid.',
                              style: TextStyle(fontSize: 13),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMonospace = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateTimeString);
      final localDate = date.toLocal();
      return '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')} '
          '${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}
