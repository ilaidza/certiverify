import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'storage_service.dart';

class BlockchainService {
  // Hyperledger Fabric connection settings
  static const String fabricGatewayUrl = 'grpc://localhost:7051';
  static const String channelName = 'credential-channel';
  static const String chaincodeName = 'certificate-cc';

  // Simulated blockchain operations (replace with actual Fabric SDK)

  /// SHA-256 hash computation for certificate data
  static String computeHash(Map<String, dynamic> certificateData) {
    final jsonString = jsonEncode(certificateData);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a unique transaction ID
  static String generateTransactionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return '0x${sha256.convert(bytes).toString().substring(0, 32)}';
  }

  /// Issue a new certificate to the blockchain
  static Future<Map<String, dynamic>> issueCertificate({
    required String institutionId,
    required String studentName,
    required String matricNumber,
    required String degree,
    required String classification,
    required String issueDate,
    required String graduationDate,
    required String certificateFileHash,
  }) async {
    try {
      // Create certificate object
      final certificateData = {
        'certificateId': generateTransactionId(),
        'studentName': studentName,
        'matricNumber': matricNumber,
        'degree': degree,
        'institutionId': institutionId,
        'classification': classification,
        'issueDate': issueDate,
        'graduationDate': graduationDate,
        'fileHash': certificateFileHash,
        'status': 'ACTIVE',
        'issuedAt': DateTime.now().toIso8601String(),
      };

      // Compute SHA-256 hash of the certificate
      final hash = computeHash(certificateData);
      certificateData['hash'] = hash;

      // In production: Submit to Hyperledger Fabric endorsing peers
      // await _submitTransaction('IssueCertificate', [certificateData]);

      // Simulate transaction delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Generate transaction ID from blockchain
      final transactionId = generateTransactionId();

      // Store in local cache
      await StorageService.saveCertificate({
        ...certificateData,
        'transactionId': transactionId,
      });

      return {
        'success': true,
        'transactionId': transactionId,
        'hash': hash,
        'certificate': certificateData,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify a certificate against the blockchain
  static Future<Map<String, dynamic>> verifyCertificate({
    required String transactionId,
    required String presentedCertificateHash,
  }) async {
    try {
      // Check local cache first
      final cached = StorageService.getCertificate(transactionId);
      if (cached != null) {
        final isValid = cached['hash'] == presentedCertificateHash;
        return {
          'success': true,
          'valid': isValid,
          'certificate': cached,
          'source': 'cache',
        };
      }

      // In production: Query Hyperledger Fabric ledger
      // final result = await _queryLedger('VerifyCertificate', [transactionId, presentedCertificateHash]);

      // Simulate blockchain query delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Simulate finding the certificate
      // This would normally come from the ledger
      final isValid = true; // Replace with actual verification

      return {'success': true, 'valid': isValid, 'source': 'blockchain'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Revoke a certificate on the blockchain
  static Future<Map<String, dynamic>> revokeCertificate({
    required String transactionId,
    required String institutionId,
    required String reason,
  }) async {
    try {
      // In production: Submit revocation to Hyperledger Fabric
      // await _submitTransaction('RevokeCertificate', [transactionId, reason]);

      // Simulate transaction delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Update local cache
      final cached = StorageService.getCertificate(transactionId);
      if (cached != null) {
        cached['status'] = 'REVOKED';
        cached['revocationReason'] = reason;
        cached['revokedAt'] = DateTime.now().toIso8601String();
        await StorageService.saveCertificate(cached);
      }

      return {'success': true, 'message': 'Certificate revoked successfully'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get certificate history from blockchain
  static Future<List<Map<String, dynamic>>> getCertificateHistory(
    String transactionId,
  ) async {
    try {
      // In production: Query blockchain history
      // final history = await _queryLedger('GetCertificateHistory', [transactionId]);

      // Simulate delay
      await Future.delayed(const Duration(milliseconds: 200));

      // Return mock history
      return [
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String(),
          'action': 'ISSUED',
          'actor': 'University of Lagos',
        },
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 15))
              .toIso8601String(),
          'action': 'VERIFIED',
          'actor': 'Kuda Bank',
        },
        {
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'action': 'VERIFIED',
          'actor': 'Andela Inc.',
        },
      ];
    } catch (e) {
      print('Error fetching certificate history: $e');
      return [];
    }
  }

  /// Get institution statistics from blockchain
  static Future<Map<String, dynamic>> getInstitutionStats(
    String institutionId,
  ) async {
    try {
      // In production: Query blockchain for institution stats
      // final stats = await _queryLedger('GetInstitutionStats', [institutionId]);

      return {
        'totalCertificatesIssued': 12450,
        'activeCertificates': 11980,
        'revokedCertificates': 470,
        'totalVerifications': 3210,
      };
    } catch (e) {
      return {
        'totalCertificatesIssued': 0,
        'activeCertificates': 0,
        'revokedCertificates': 0,
        'totalVerifications': 0,
      };
    }
  }

  /// Check blockchain network health
  static Future<bool> healthCheck() async {
    try {
      // In production: Ping peer nodes
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  // These would be implemented with actual Hyperledger Fabric SDK
  /*
  static Future<dynamic> _submitTransaction(String functionName, List<dynamic> args) async {
    // Use fabric_gateway SDK for Go or Node.js backend
    // For Flutter, you'd typically call your backend API
    // which then interacts with Fabric
  }
  
  static Future<dynamic> _queryLedger(String functionName, List<dynamic> args) async {
    // Query the ledger via your backend API
  }
  */
}
