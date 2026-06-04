import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get error => _error;

  Future<bool> checkAuthStatus() async {
    final userData = StorageService.getUser();
    if (userData != null) {
      _currentUser = User.fromJson(userData);

      // Check if token is expired
      if (StorageService.isTokenExpired()) {
        await logout();
        return false;
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _apiService.login(email, password);

    if (result['success']) {
      _currentUser = result['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    notifyListeners();
  }

  bool get canIssueCertificates {
    return _currentUser?.isInstitutionAdmin ?? false;
  }

  bool get canRevokeCertificates {
    return _currentUser?.isInstitutionAdmin ?? false;
  }

  bool get canVerifyCertificates {
    return true;
  }
}
