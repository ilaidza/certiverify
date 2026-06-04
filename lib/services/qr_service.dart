import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRService {
  /// Generate QR code widget from transaction ID
  static Widget generateQRCode(String transactionId, {double size = 200}) {
    return QrImageView(
      data: transactionId,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      eyeStyle: const QrEyeStyle(
        color: Color(0xFF00236F),
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: Color(0xFF00236F),
        dataModuleShape: QrDataModuleShape.square,
      ),
    );
  }

  /// Generate QR code as image bytes for PDF embedding
  static Future<Uint8List> generateQRCodeAsBytes(
    String transactionId, {
    double size = 200.0,
  }) async {
    final qrCode = await QrPainter(
      data: transactionId,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        color: Color(0xFF00236F),
        eyeShape: QrEyeShape.square,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        color: Color(0xFF00236F),
        dataModuleShape: QrDataModuleShape.square,
      ),
    ).toImageData(size);

    return qrCode?.buffer.asUint8List() ?? Uint8List(0);
  }

  /// Validate QR code string format
  static bool isValidQRCode(String data) {
    // Transaction ID format: 0x followed by 64 hex characters
    final txIdPattern = RegExp(r'^0x[a-fA-F0-9]{64}$');
    // URL pattern
    final urlPattern = RegExp(
      r'^https?://verify\.credchain\.com\.ng/cert/(.+)$',
    );

    return txIdPattern.hasMatch(data) || urlPattern.hasMatch(data);
  }

  /// Extract transaction ID from QR code data
  static String extractTransactionId(String qrData) {
    // If it's a URL, extract the last part
    if (qrData.startsWith('http')) {
      return qrData.split('/').last;
    }
    return qrData;
  }

  /// Generate verification URL for QR code
  static String generateVerificationUrl(String transactionId) {
    return 'https://verify.credchain.com.ng/cert/$transactionId';
  }

  /// Generate certificate data for QR embedding
  static String generateCertificateQRData(String transactionId) {
    // You can encode more data if needed, but keep it concise
    return generateVerificationUrl(transactionId);
  }
}
