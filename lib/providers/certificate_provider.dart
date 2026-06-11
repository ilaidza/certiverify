import 'package:flutter/material.dart';
import '../models/certificate.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class CertificateProvider extends ChangeNotifier {
  List<Certificate> _userCertificates = [];
  final List<Certificate> _recentVerifications = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  List<Certificate> get userCertificates => _userCertificates;
  List<Certificate> get recentVerifications => _recentVerifications;
  bool get isLoading => _isLoading;

  int get totalVerificationCount =>
      _recentVerifications.fold(0, (sum, cert) => sum + cert.verificationCount);

  Future<void> fetchUserCertificates() async {
    _isLoading = true;
    notifyListeners();

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data
    _userCertificates = [
      Certificate(
        id: 'cert_001',
        transactionId: '0x7f8e9a2b3c4d5e6f',
        hash:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        studentName: 'Atalese Enoch Ade',
        matricNumber: 'CSC/20/4835',
        degree: 'B.Sc. Computer Science',
        institution: 'Federal University of Technology, Akure',
        institutionId: 'FUTA',
        issueDate: '2023-11-15',
        classification: 'First Class Honours',
        issuedAt: DateTime.now().subtract(const Duration(days: 30)),
        verificationCount: 12,
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  // Add these variables to your CertificateProvider class
  int _totalGraduates = 0;
  bool _isBlockchainHealthy = false;
  String _blockchainStatus = 'checking...';
  String _blockchainService = '';
  String _lastHealthCheck = '';

  int get totalGraduates => _totalGraduates;
  bool get isBlockchainHealthy => _isBlockchainHealthy;
  String get blockchainStatus => _blockchainStatus;
  String get blockchainService => _blockchainService;
  String get lastHealthCheck => _lastHealthCheck;

  // Add these methods to your CertificateProvider class
  Future<void> fetchTotalGraduates() async {
    final result = await _apiService.getTotalGraduates();
    if (result['success']) {
      _totalGraduates = result['total'];
      notifyListeners();
    }
  }

  Future<void> fetchHealthStatus() async {
    final result = await _apiService.getHealthStatus();
    if (result['success']) {
      _isBlockchainHealthy = result['isHealthy'];
      _blockchainStatus = result['status'];
      _blockchainService = result['service'];
      _lastHealthCheck = result['timestamp'];
    } else {
      _isBlockchainHealthy = false;
      _blockchainStatus = 'unhealthy';
    }
    notifyListeners();
  }

  // Call these when dashboard loads
  // (loadDashboardData defined later to include recent activities)

  Future<Certificate?> verifyCertificate(String transactionId) async {
    // Check offline first
    final cached = StorageService.getCertificate(transactionId);
    if (cached != null) {
      return Certificate.fromJson(cached);
    }

    // Simulate blockchain query
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock - return a found certificate
    final cert = Certificate(
      id: 'cert_001',
      transactionId: transactionId,
      hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      studentName: 'Oduola Abidemi',
      matricNumber: 'CSC/20/4861',
      degree: 'B.Sc. Computer Science',
      institution: 'Federal University of Technology, Akure',
      institutionId: 'FUTA',
      issueDate: '2023-11-15',
      classification: 'First Class Honours',
      issuedAt: DateTime.now().subtract(const Duration(days: 30)),
      verificationCount: 13,
    );

    // Cache for offline
    await StorageService.saveCertificate(cert.toJson());

    // Update recent verifications
    _recentVerifications.insert(0, cert);
    if (_recentVerifications.length > 10) _recentVerifications.removeLast();

    notifyListeners();
    return cert;
  }

  Future<bool> issueCertificate(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    // Simulate blockchain transaction
    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // Update the recentActivities getter and fetch method

  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  Future<void> fetchRecentActivities() async {
    // First try to get real verification history
    final activities = await _apiService.getVerificationHistory();

    if (activities.isNotEmpty) {
      _recentActivities = activities;
    } else {
      // Fallback: Use certificates as recent activity
      _recentActivities = _userCertificates.map((cert) {
        return {
          'credential_id': cert.id,
          'action': 'ISSUED',
          'timestamp': cert.issuedAt.toIso8601String(),
          'verifier': cert.institution,
          'status': 'success',
          'student_name': cert.studentName,
          'degree': cert.degree,
        };
      }).toList();

      // Sort by most recent first
      _recentActivities.sort(
        (a, b) => b['timestamp'].compareTo(a['timestamp']),
      );
    }

    notifyListeners();
  }
}
