import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/certificate_provider.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';
import 'verification_result_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _flashlightOn = false;
  bool _isProcessing = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleFlashlight() {
    setState(() {
      _flashlightOn = !_flashlightOn;
      _scannerController.toggleTorch();
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_isScanning || _isProcessing) return;

    final barcode = capture.barcodes.first;
    final scannedData = barcode.rawValue;

    if (scannedData != null && scannedData.isNotEmpty) {
      setState(() {
        _isScanning = false;
        _isProcessing = true;
      });

      // Extract credential ID from QR code
      // The QR code could contain just the ID or a URL
      String credentialId = scannedData;

      // If it's a URL, extract the ID from the end
      if (scannedData.startsWith('http')) {
        final uri = Uri.tryParse(scannedData);
        if (uri != null) {
          // Get the last part of the path
          credentialId = uri.pathSegments.last;
        }
      }

      // Also handle JSON payload format
      if (scannedData.contains('"tx_id"')) {
        try {
          final jsonData = jsonDecode(scannedData);
          credentialId = jsonData['tx_id'] ?? credentialId;
        } catch (e) {
          // Not JSON, use as is
        }
      }

      print('Extracted Credential ID: $credentialId');

      // Verify the credential with the API
      final result = await _apiService.verifyCredential(credentialId);

      setState(() => _isProcessing = false);

      if (mounted) {
        // Navigate to verification result screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerificationResultScreen(
              credentialId: credentialId,
              verificationResult: result,
            ),
          ),
        );

        // Resume scanning after returning
        setState(() {
          _isScanning = true;
          _isProcessing = false;
        });
        _scannerController.start();
      }
    }
  }

  Future<void> _pickFromGallery() async {
    // For gallery image picker - can be implemented later
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gallery import coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Credential'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _flashlightOn ? Icons.flashlight_off : Icons.flashlight_on,
            ),
            onPressed: _toggleFlashlight,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(controller: _scannerController, onDetect: _onDetect),

          // Overlay with cutout
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(width: double.infinity, height: double.infinity),
          ),

          // Scanner frame corners
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  // Top-left corner
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.secondary, width: 4),
                          left: BorderSide(color: AppTheme.secondary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Top-right corner
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.secondary, width: 4),
                          right: BorderSide(
                            color: AppTheme.secondary,
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-left corner
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.secondary,
                            width: 4,
                          ),
                          left: BorderSide(color: AppTheme.secondary, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right corner
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.secondary,
                            width: 4,
                          ),
                          right: BorderSide(
                            color: AppTheme.secondary,
                            width: 4,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  // Scanning line animation
                  Positioned(
                    left: 12,
                    right: 12,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, value * 260),
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppTheme.secondary,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.secondary.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verifying credential...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Position QR code within the frame',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),

          // Gallery import button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Upload from Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black54,
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 280,
            height: 280,
          ),
          const Radius.circular(24),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
