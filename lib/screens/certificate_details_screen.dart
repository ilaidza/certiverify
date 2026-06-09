import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/pdf_service.dart';
import '../utils/theme.dart';

class CredentialDetailsScreen extends StatefulWidget {
  final String credentialId;

  const CredentialDetailsScreen({super.key, required this.credentialId});

  @override
  State<CredentialDetailsScreen> createState() =>
      _CredentialDetailsScreenState();
}

class _CredentialDetailsScreenState extends State<CredentialDetailsScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _credential;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  bool _isGeneratingPDF = false;
  String? _error;
  Uint8List? _qrCodeImage;

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

    final result = await _apiService.getCredentialDetails(widget.credentialId);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _credential = result;
        _generateQRCode();
      } else {
        _error = result['error'];
      }
    });
  }

  void _generateQRCode() {
    // Generate QR code from credential ID
    final qrData = _credential?['credentialId'] ?? widget.credentialId;
    // Use qr_flutter to generate QR as image
    // For PDF, we'll generate on demand
  }

  List<Map<String, dynamic>> _safeCredentialsToList(dynamic credentials) {
    if (credentials == null) return [];
    if (credentials is List) {
      return credentials.map((e) {
        if (e is Map<String, dynamic>) return e;
        return Map<String, dynamic>.from(e);
      }).toList();
    }
    if (credentials is Map) {
      return [Map<String, dynamic>.from(credentials)];
    }
    return [];
  }

  Future<Uint8List?> _generateQRCodeImage() async {
    final qrData = _credential?['credentialId'] ?? widget.credentialId;
    try {
      final qrImage = await QrPainter(
        data: qrData,
        version: QrVersions.auto,
        eyeStyle: const QrEyeStyle(
          color: Color(0xFF00236F),
          eyeShape: QrEyeShape.square,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          color: Color(0xFF00236F),
          dataModuleShape: QrDataModuleShape.square,
        ),
      ).toImageData(200);

      return qrImage?.buffer.asUint8List();
    } catch (e) {
      print('Error generating QR code: $e');
      return null;
    }
  }

  Future<void> _downloadPDF() async {
    setState(() => _isGeneratingPDF = true);

    final qrImageBytes = await _generateQRCodeImage();

    final pdfBytes = await PDFService.generateCertificatePDF(
      credential: _credential!,
      qrCodeImage: qrImageBytes,
    );

    setState(() => _isGeneratingPDF = false);

    // Show save options dialog
    await PDFService.showSaveOptionsDialog(
      pdfBytes: pdfBytes,
      fileName: 'certificate_${widget.credentialId.substring(0, 8)}',
      context: context,
    );
  }

  Future<void> _shareCertificate() async {
    setState(() => _isGeneratingPDF = true);

    final qrImageBytes = await _generateQRCodeImage();

    final pdfBytes = await PDFService.generateCertificatePDF(
      credential: _credential!,
      qrCodeImage: qrImageBytes,
    );

    await PDFService.saveAndSharePDF(
      pdfBytes: pdfBytes,
      fileName: 'certificate_${widget.credentialId.substring(0, 8)}',
      context: context,
    );

    setState(() => _isGeneratingPDF = false);
  }

  Future<void> _showActionDialog({
    required String title,
    required String message,
    required String actionText,
    required Color actionColor,
    required Future<void> Function(String?) onConfirm,
    bool showReasonField = false,
  }) async {
    String? reason;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message),
                if (showReasonField) ...[
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => reason = value,
                    decoration: const InputDecoration(
                      labelText: 'Reason *',
                      hintText: 'Enter reason for this action',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (showReasonField && (reason == null || reason!.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a reason')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  onConfirm(reason);
                },
                style: ElevatedButton.styleFrom(backgroundColor: actionColor),
                child: Text(actionText),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _revokeCredential() async {
    await _showActionDialog(
      title: 'Revoke Certificate',
      message:
          'Are you sure you want to revoke this certificate? This action can be reversed later.',
      actionText: 'Revoke',
      actionColor: AppTheme.error,
      showReasonField: true,
      onConfirm: (reason) async {
        setState(() => _isActionInProgress = true);

        final result = await _apiService.revokeCredential(
          credentialId: widget.credentialId,
          reason: reason ?? 'No reason provided',
        );

        setState(() => _isActionInProgress = false);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate revoked successfully'),
                backgroundColor: AppTheme.secondary,
              ),
            );
            await _fetchCredentialDetails();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error']),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _suspendCredential() async {
    await _showActionDialog(
      title: 'Suspend Certificate',
      message:
          'Are you sure you want to suspend this certificate? It will be temporarily disabled.',
      actionText: 'Suspend',
      actionColor: Colors.orange,
      showReasonField: true,
      onConfirm: (reason) async {
        setState(() => _isActionInProgress = true);

        final result = await _apiService.suspendCredential(
          credentialId: widget.credentialId,
          reason: reason ?? 'No reason provided',
        );

        setState(() => _isActionInProgress = false);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate suspended successfully'),
                backgroundColor: AppTheme.secondary,
              ),
            );
            await _fetchCredentialDetails();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error']),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _reinstateCredential() async {
    await _showActionDialog(
      title: 'Reinstate Certificate',
      message:
          'Are you sure you want to reinstate this certificate? It will become active again.',
      actionText: 'Reinstate',
      actionColor: AppTheme.secondary,
      showReasonField: false,
      onConfirm: (_) async {
        setState(() => _isActionInProgress = true);

        final result = await _apiService.reinstateCredential(
          credentialId: widget.credentialId,
        );

        setState(() => _isActionInProgress = false);

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate reinstated successfully'),
                backgroundColor: AppTheme.secondary,
              ),
            );
            await _fetchCredentialDetails();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error']),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.currentUser?.isInstitutionAdmin ?? false;
    final status = _credential?['status'] ?? '';
    final qrData = _credential?['credentialId'] ?? widget.credentialId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Details'),
        actions: [
          if (!_isLoading && !_isActionInProgress)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _fetchCredentialDetails();
                    break;
                  case 'share':
                    _shareCertificate();
                    break;
                  case 'download':
                    _downloadPDF();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Refresh'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share Certificate'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Download PDF'),
                    ],
                  ),
                ),
              ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(status)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 48,
                          color: _getStatusColor(status),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'VERIFICATION QR CODE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.outlineVariant,
                              ),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 180,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                color: Color(0xFF00236F),
                                eyeShape: QrEyeShape.square,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                color: Color(0xFF00236F),
                                dataModuleShape: QrDataModuleShape.square,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan this QR code to verify the certificate',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Credential Details Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CREDENTIAL INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildDetailRow(
                          'Credential ID',
                          _credential?['credentialId'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Student Name',
                          _credential?['studentName'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Student ID',
                          _credential?['studentId'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Degree',
                          _credential?['degree'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        if (_credential?['degreeClass'] != null &&
                            _credential?['degreeClass'] != '')
                          _buildDetailRow(
                            'Degree Class',
                            _credential?['degreeClass'],
                          ),
                        if (_credential?['cgpa'] != null &&
                            _credential!['cgpa'].toString().isNotEmpty)
                          _buildDetailRow(
                            'CGPA',
                            _credential!['cgpa'].toString(),
                          ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Institution',
                          _credential?['institutionName'] ?? 'N/A',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Graduation Date',
                          _formatDate(_credential?['graduationDate'] ?? ''),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Issued At',
                          _formatDateTime(_credential?['issuedAt'] ?? ''),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          'Issued By',
                          _credential?['issuedBy'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Download PDF',
                          color: AppTheme.primary,
                          onPressed: _downloadPDF,
                          isLoading: _isGeneratingPDF,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          color: AppTheme.secondary,
                          onPressed: _shareCertificate,
                          isLoading: _isGeneratingPDF,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Admin Actions (Only visible to Institution Admins)
                  if (isAdmin) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'ADMIN ACTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (status == 'active') ...[
                      _buildActionButton(
                        label: 'Revoke Certificate',
                        color: AppTheme.error,
                        onPressed: _revokeCredential,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        label: 'Suspend Certificate',
                        color: Colors.orange,
                        onPressed: _suspendCredential,
                        isFullWidth: true,
                      ),
                    ] else if (status == 'revoked' ||
                        status == 'suspended') ...[
                      _buildActionButton(
                        icon: Icons.restore,
                        label: 'Reinstate Certificate',
                        color: AppTheme.secondary,
                        onPressed: _reinstateCredential,
                        isFullWidth: true,
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, size: 20, color: AppTheme.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This certificate is recorded on the CredChain Blockchain Network',
                            style: TextStyle(fontSize: 12),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isFullWidth = false,
    bool isLoading = false,
  }) {
    final button = OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      label: Text(isLoading ? 'Processing...' : label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.secondary;
      case 'revoked':
        return AppTheme.error;
      case 'suspended':
        return Colors.orange;
      default:
        return AppTheme.outline;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'revoked':
        return Icons.cancel;
      case 'suspended':
        return Icons.pause_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString.split('T')[0];
    }
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'N/A';
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
