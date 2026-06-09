import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/certificate.dart';
import '../services/blockchain_service.dart';
import '../services/pdf_service.dart';
import '../services/qr_service.dart';
import '../utils/theme.dart';

class CertificateDetailsScreen extends StatefulWidget {
  final Certificate certificate;

  const CertificateDetailsScreen({
    super.key,
    required this.certificate,
    required credentialId,
  });

  @override
  State<CertificateDetailsScreen> createState() =>
      _CertificateDetailsScreenState();
}

class _CertificateDetailsScreenState extends State<CertificateDetailsScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    _history = await BlockchainService.getCertificateHistory(
      widget.certificate.transactionId,
    );
    setState(() => _isLoadingHistory = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificate Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadPDF(),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareCertificate(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Digital Certificate Card
            _buildDigitalCertificate(),
            const SizedBox(height: 24),

            // Security & Verification Section
            Text(
              'Security & Verification',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSecurityCard(),
            const SizedBox(height: 24),

            // Blockchain History
            Text(
              'Blockchain History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildHistoryTimeline(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalCertificate() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with seal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    size: 32,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.certificate.institution,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Office of the Registrar',
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

          // Certificate Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'CERTIFICATE OF GRADUATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'This is to certify that',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.certificate.studentName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Matric Number: ${widget.certificate.matricNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'has been admitted to the degree of',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.certificate.degree,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.certificate.classification,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.certificate.issueDate,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.certificate.isActive
                                  ? AppTheme.secondaryContainer.withOpacity(0.3)
                                  : AppTheme.errorContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.certificate.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.certificate.isActive
                                    ? AppTheme.secondary
                                    : AppTheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, size: 16, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Verified on CredChain Blockchain',
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
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.outlineVariant,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: QRService.generateQRCode(
                widget.certificate.transactionId,
                size: 160,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Scan QR code to verify authenticity instantly',
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),

          // Hashes
          _buildHashRow(
            label: 'Credential Hash (SHA-256)',
            value: widget.certificate.hash,
          ),
          const SizedBox(height: 16),
          _buildHashRow(
            label: 'Blockchain Transaction ID',
            value: widget.certificate.transactionId,
          ),
        ],
      ),
    );
  }

  Widget _buildHashRow({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.info_outline, size: 14, color: AppTheme.outline),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTimeline() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No transaction history available',
            style: TextStyle(color: AppTheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _history.length,
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final item = _history[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getActionColor(item['action']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getActionIcon(item['action']),
                color: _getActionColor(item['action']),
              ),
            ),
            title: Text(item['action']),
            subtitle: Text(item['actor']),
            trailing: Text(
              _formatDate(item['timestamp']),
              style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
            ),
          );
        },
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'ISSUED':
        return Icons.add_circle;
      case 'VERIFIED':
        return Icons.verified;
      case 'REVOKED':
        return Icons.cancel;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'ISSUED':
        return AppTheme.primary;
      case 'VERIFIED':
        return AppTheme.secondary;
      case 'REVOKED':
        return AppTheme.error;
      default:
        return AppTheme.outline;
    }
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.month}/${date.day}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _verifyAgain(),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Verify Credential Again'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _downloadPDF(),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Download PDF Certificate'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  void _verifyAgain() {
    Navigator.pop(context);
  }

  Future<void> _downloadPDF() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Generate QR code image
    final qrBytes = await QRService.generateQRCodeAsBytes(
      widget.certificate.transactionId,
    );

    // Generate PDF
    final pdfBytes = await PDFService.generateCertificatePDF(
      certificate: widget.certificate,
      qrCodeImage: qrBytes,
    );

    // Save PDF
    final file = await PDFService.savePDF(
      pdfBytes,
      'certificate_${widget.certificate.transactionId.substring(0, 8)}',
    );

    // Close dialog
    if (context.mounted) Navigator.pop(context);

    if (file != null && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF saved successfully')));
    }
  }

  Future<void> _shareCertificate() async {
    // Generate PDF and share
    final qrBytes = await QRService.generateQRCodeAsBytes(
      widget.certificate.transactionId,
    );
    final pdfBytes = await PDFService.generateCertificatePDF(
      certificate: widget.certificate,
      qrCodeImage: qrBytes,
    );
    await PDFService.sharePDF(
      pdfBytes,
      'certificate_${widget.certificate.transactionId.substring(0, 8)}',
    );
  }
}
