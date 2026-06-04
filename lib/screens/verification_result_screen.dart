import 'package:flutter/material.dart';
import '../services/qr_generator_service.dart';
import '../services/qr_scan_service.dart';
import '../widgets/qr_scanner_widget.dart';

class CertificateVerificationScreen extends StatelessWidget {
  const CertificateVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Certificate')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Scan QR Code to Verify'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerWidget(
                      onScanComplete: (scannedData) {
                        // Handle successful scan
                        final transactionId =
                            QRScanService.extractTransactionId(scannedData);
                        final verificationUrl =
                            QRScanService.getVerificationUrl(scannedData);

                        // Navigate to verification result
                        Navigator.pop(context);
                        _showVerificationResult(
                          context,
                          transactionId,
                          verificationUrl,
                        );
                      },
                      onClose: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 40),
            const Text('Or manually enter certificate ID:'),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Transaction ID or URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (value) {
                  if (QRGeneratorService.isValidQRCode(value)) {
                    final transactionId =
                        QRGeneratorService.extractTransactionId(value);
                    _showVerificationResult(context, transactionId, value);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid certificate ID format'),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationResult(
    BuildContext context,
    String transactionId,
    String? url,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: $transactionId'),
            const SizedBox(height: 10),
            if (url != null) Text('URL: $url'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to certificate details
              Navigator.pop(context);
              // TODO: Navigate to certificate details screen
            },
            child: const Text('View Certificate'),
          ),
        ],
      ),
    );
  }
}
