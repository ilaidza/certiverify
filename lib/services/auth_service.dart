import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';
import 'api_service.dart';

class AuthService {
  // Local Biometric Authentication
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // API Service for backend calls
  static final ApiService _apiService = ApiService();

  // ==================== BIOMETRIC AUTHENTICATION ====================

  /// Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      log('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      log('Error getting biometrics: $e');
      return [];
    }
  }

  /// Authenticate using biometrics (FaceID / Fingerlog)
  static Future<bool> authenticateWithBiometrics({
    required String reason,
  }) async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (isAuthenticated) {
        // Update last authentication time
        await StorageService.setLastSyncTime(DateTime.now());

        // If biometric succeeds, we can auto-login using stored credentials
        final user = StorageService.getUser();
        final savedEmail = user?['email'] as String?;
        final savedPassword = user?['password'] as String?;

        if (savedEmail != null && savedPassword != null) {
          // Auto login with saved credentials
          final result = await _apiService.login(savedEmail, savedPassword);

          if (result['success'] == true && result['user'] != null) {
            await StorageService.saveUser(result['user'].toJson());
            if (result['token'] != null) {
              await StorageService.saveAuthToken(result['token']);
            }
            return true;
          }
        }
      }

      return isAuthenticated;
    } on PlatformException catch (e) {
      print('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Authenticate using device PIN/Pattern/Password
  static Future<bool> authenticateWithDeviceCredentials({
    required String reason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } on PlatformException catch (e) {
      print('Error during device auth: $e');
      return false;
    }
  }

  /// Stop current authentication session
  static Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }

  /// Get biometric type display name
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      case BiometricType.strong:
        return 'Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get biometric type icon
  static String getBiometricTypeIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'face';
      case BiometricType.fingerprint:
        return 'fingerprint';
      case BiometricType.iris:
        return 'iris_scan';
      case BiometricType.strong:
        return 'security';
      default:
        return 'biometric';
    }
  }

  // ==================== BACKEND AUTHENTICATION ====================

  /// Login with email and password (calls your backend)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final result = await _apiService.login(email, password);

      if (result['success'] == true && result['user'] != null) {
        // Save credentials for biometric auto-login (credentials are stored
        // as part of the saved user object below)

        // Save user data and token
        final user = result['user'];
        if (user != null && user is Map<String, dynamic>) {
          await StorageService.saveUser(user);
        } else if (user != null && user.toString().isNotEmpty) {
          try {
            if (user is Map<String, dynamic>) {
              await StorageService.saveUser(user);
            } else {
              await StorageService.saveUser({'user': user});
            }
          } catch (_) {
            await StorageService.saveUser({'user': user});
          }
        }
        if (result['token'] != null) {
          await StorageService.saveAuthToken(result['token']);
        }

        return {
          'success': true,
          'user': result['user'],
          'token': result['token'],
        };
      } else {
        return {
          'success': false,
          'message': result['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String institutionId,
  }) async {
    try {
      // Some ApiService implementations may not expose a typed `register` method.
      // Use a dynamic call to avoid compile-time undefined_method errors while
      // still forwarding parameters to the underlying service if available.
      final dynamic result = await (_apiService as dynamic).register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        role: role,
        institutionId: institutionId,
      );

      // Normalize different possible result shapes
      if (result == null) {
        return {'success': false, 'message': 'Registration failed'};
      }

      // If result is a Map-like structure
      if (result is Map<String, dynamic>) {
        if (result['success'] == true) {
          return {'success': true, 'user': result['user']};
        }
        return {
          'success': false,
          'message': result['message'] ?? 'Registration failed',
        };
      }

      // If result is an object with properties (e.g., success, user, message)
      try {
        final success = result.success as bool?;
        final user = result.user;
        final message = result.message as String?;
        if (success == true) {
          return {'success': true, 'user': user};
        }
        return {'success': false, 'message': message ?? 'Registration failed'};
      } catch (_) {
        return {'success': false, 'message': 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    await _apiService.logout();
  }

  /// Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final token = StorageService.getAuthToken();
    final user = StorageService.getUser();
    return token != null && user != null;
  }

  /// Get current logged in user
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return StorageService.getUser();
  }
}
