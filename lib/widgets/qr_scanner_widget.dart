import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scan_service.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScanComplete;
  final VoidCallback? onScanError;
  final VoidCallback? onClose;

  const QRScannerWidget({
    Key? key,
    required this.onScanComplete,
    this.onScanError,
    this.onClose,
  }) : super(key: key);

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  MobileScannerController scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
    autoStart: true,
  );
  bool isScanning = true;
  String? errorMessage;

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: scannerController.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => scannerController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: scannerController.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner view
          MobileScanner(
            controller: scannerController,
            onDetect: (capture) {
              if (!isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final scannedData = QRScanService.processBarcode(barcode);
                if (scannedData != null && scannedData.isNotEmpty) {
                  setState(() {
                    isScanning = false;
                  });

                  // Stop scanning after successful scan
                  scannerController.stop();

                  // Validate and process
                  if (QRScanService.isValidQRCode(scannedData)) {
                    widget.onScanComplete(scannedData);
                  } else {
                    _showInvalidQRDialog(scannedData);
                  }
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Camera Error: ${error.errorCode}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                        scannerController.start();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Scanner overlay guide
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -1,
                      left: -1,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green, width: 4),
                            left: BorderSide(color: Colors.green, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green, width: 4),
                            right: BorderSide(color: Colors.green, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -1,
                      left: -1,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green, width: 4),
                            left: BorderSide(color: Colors.green, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -1,
                      right: -1,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.green, width: 4),
                            right: BorderSide(color: Colors.green, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom instruction
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Position QR code in the frame',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                scannerController.stop();
                if (widget.onClose != null) {
                  widget.onClose!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInvalidQRDialog(String scannedData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content: Text(
          'This QR code is not a valid certificate code.\n\nScanned: $scannedData',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isScanning = true;
              });
              scannerController.start();
            },
            child: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}
