import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanService {
  /// Process scanned barcode and return raw value
  static String? processBarcode(Barcode barcode) {
    if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
      return barcode.rawValue;
    }
    return null;
  }

  /// Validate scanned QR code format
  static bool isValidQRCode(String data) {
    // Transaction ID format: 0x followed by 64 hex characters
    final txIdPattern = RegExp(r'^0x[a-fA-F0-9]{64}$');
    // URL pattern
    final urlPattern = RegExp(
      r'^https?://verify\.credchain\.com\.ng/cert/(.+)$',
    );
    // Generic URL pattern
    final genericUrlPattern = RegExp(r'^https?://');

    return txIdPattern.hasMatch(data) ||
        urlPattern.hasMatch(data) ||
        genericUrlPattern.hasMatch(data);
  }

  /// Extract transaction ID from scanned QR data
  static String extractTransactionId(String qrData) {
    // If it's a URL, extract the last part
    if (qrData.startsWith('http')) {
      final parts = qrData.split('/');
      return parts.isNotEmpty ? parts.last : qrData;
    }
    return qrData;
  }

  /// Get verification URL from QR data
  static String? getVerificationUrl(String qrData) {
    if (qrData.startsWith('http')) {
      return qrData;
    }
    if (qrData.startsWith('0x') && qrData.length == 66) {
      return 'https://verify.credchain.com.ng/cert/$qrData';
    }
    return null;
  }
}
