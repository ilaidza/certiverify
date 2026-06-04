import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiService {
  // IMPORTANT: Use HTTPS, not HTTP!
  static const String baseUrl =
      'https://academic-credential-verification.onrender.com';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 90,
        ), // Longer timeout for free tier
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Automatically follow redirects (307 redirects)
        followRedirects: true,
        // Don't throw on any status codes - we'll handle them manually
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Allow self-signed certificates (for development)
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        };

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = StorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('REQUEST: ${options.method} ${options.path}');
          print('HEADERS: ${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('RESPONSE: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('ERROR: ${error.response?.statusCode} - ${error.message}');
          print('ERROR TYPE: ${error.type}');

          // Handle redirects manually if needed
          if (error.response?.statusCode == 307 ||
              error.response?.statusCode == 302) {
            final location = error.response?.headers['location']?.first;
            if (location != null) {
              print('Redirecting to: $location');
              final newUrl = location.startsWith('http')
                  ? location
                  : '${baseUrl}$location';
              try {
                final response = await _dio.get(newUrl);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.resolve(
              Response(
                requestOptions: error.requestOptions,
                statusCode: 500,
                data: {'message': 'Request timeout. Please try again.'},
              ),
            );
          }

          if (error.response?.statusCode == 401) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              final newToken = StorageService.getAuthToken();
              opts.headers['Authorization'] = 'Bearer $newToken';
              final retryResponse = await _dio.request(
                opts.path,
                options: Options(method: opts.method, headers: opts.headers),
                data: opts.data,
              );
              return handler.resolve(retryResponse);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await StorageService.saveAuthToken(data['access_token']);
        await StorageService.saveRefreshToken(data['refresh_token']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ==================== AUTHENTICATION ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to: $baseUrl/api/v1/auth/login');
      print('Email: $email');

      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      print('Login response status: ${response.statusCode}');
      print('Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await StorageService.saveAuthToken(data['access_token']);
        await StorageService.saveRefreshToken(data['refresh_token']);
        await StorageService.saveTokenType(data['token_type']);
        await StorageService.setTokenExpiry(data['expires_in']);

        // Save user data
        final userData = data['user'];
        final user = User(
          id: userData['user_id'],
          name: userData['institution_name'] ?? userData['email'].split('@')[0],
          email: userData['email'],
          role: _mapRole(userData['role']),
          institutionId: userData['institution_id'],
          institutionName: userData['institution_name'],
          createdAt: DateTime.now(),
        );

        await StorageService.saveUser(user.toJson());

        return {
          'success': true,
          'user': user,
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
        };
      }

      return {
        'success': false,
        'error':
            response.data['message'] ??
            'Login failed with status ${response.statusCode}',
      };
    } on DioException catch (e) {
      print('Login DioException: ${e.type}');
      print('Login error message: ${e.message}');
      print('Login error response: ${e.response?.data}');

      String errorMessage = 'Network error. Please check your connection.';

      if (e.response?.statusCode == 307) {
        // This should be handled by followRedirects now, but just in case
        errorMessage = 'Redirect error. Please ensure you are using HTTPS.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Server timeout. The free tier service might be waking up. Please try again in 30 seconds.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (e.response != null && e.response!.data != null) {
        errorMessage =
            e.response!.data['message'] ??
            e.response!.data['error'] ??
            'Login failed';
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      print('Login unexpected error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  UserRole _mapRole(String role) {
    switch (role) {
      case 'institution_admin':
        return UserRole.institutionAdmin;
      case 'student':
        return UserRole.student;
      case 'verifier':
        return UserRole.verifier;
      default:
        return UserRole.verifier;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    } finally {
      await StorageService.clear();
    }
  }

  // ==================== CERTIFICATE OPERATIONS ====================

  Future<Map<String, dynamic>> issueCertificate({
    required String studentId,
    required String studentName,
    required String institutionCode,
    required String degree,
    required String graduationDate,
    required String issuerDigitalSignature,
  }) async {
    try {
      final requestBody = {
        'student_id': studentId,
        'student_name': studentName,
        'institution_code': institutionCode,
        'degree': degree,
        'graduation_date': graduationDate,
        'issuer_digital_signature': issuerDigitalSignature,
      };

      print('Request Body: $requestBody');

      final response = await _dio.post(
        '/api/v1/institution/credentials/issue',
        data: requestBody,
      );

      print('Issue certificate response status: ${response.statusCode}');
      print('Issue certificate response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'transactionId': data['tx_id'],
          'qrCodeBase64': data['qr_code_base64'],
          'verificationUrl': data['verification_url'],
          'issuedAt': data['issued_at'],
          'issuedBy': data['issued_by'],
          'issuedByUser': data['issued_by_user'],
        };
      }

      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to issue certificate',
      };
    } on DioException catch (e) {
      print('Issue certificate error: ${e.response?.data}');

      String errorMessage = 'Failed to issue certificate';
      if (e.response != null && e.response!.data != null) {
        errorMessage =
            e.response!.data['message'] ?? e.response!.data.toString();
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  Future<Map<String, dynamic>> checkCredentialStatus(
    String credentialId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/credentials/$credentialId/status',
      );

      print('Check status response status: ${response.statusCode}');
      print('Check status response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'status': data['status'],
          'checkedAt': data['checked_at'],
          'isValid': data['status'] == 'active',
        };
      }
      return {'success': false, 'error': 'Failed to check credential status'};
    } on DioException catch (e) {
      print('Check status error: ${e.response?.data}');

      String errorMessage = 'Network error';
      if (e.response?.statusCode == 404) {
        errorMessage = 'Credential not found';
      } else if (e.response?.data != null) {
        errorMessage =
            e.response!.data['message'] ?? e.response!.data.toString();
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  Future<Map<String, dynamic>> verifyCredential(String credentialId) async {
    try {
      final response = await _dio.get(
        '/api/v1/credentials/$credentialId/status',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'status': data['status'],
          'verifiedAt': data['checked_at'],
          'isValid': data['status'] == 'active',
        };
      }
      return {'success': false, 'error': 'Certificate not found or invalid'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getCredentialDetails(String credentialId) async {
    try {
      final response = await _dio.get('/api/v1/credentials/$credentialId');

      if (response.statusCode == 200) {
        return {'success': true, 'credential': response.data};
      }
      return {'success': false, 'error': 'Credential not found'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getUserCredentials() async {
    try {
      final response = await _dio.get('/api/v1/user/credentials');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('Error fetching user credentials: ${e.message}');
      return [];
    }
  }

  Future<Map<String, dynamic>> revokeCredential({
    required String credentialId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/institution/credentials/revoke',
        data: {'credential_id': credentialId, 'reason': reason},
      );

      print('Revoke credential response status: ${response.statusCode}');
      print('Revoke credential response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'message': data['message'],
          'reason': data['reason'],
          'revokedAt': data['revoked_at'],
          'revokedBy': data['revoked_by'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to revoke credential',
      };
    } on DioException catch (e) {
      print('Revoke credential error: ${e.response?.data}');

      String errorMessage = 'Network error';
      if (e.response?.statusCode == 404) {
        errorMessage = 'Credential not found';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to revoke this credential';
      } else if (e.response?.data != null) {
        errorMessage =
            e.response!.data['message'] ?? e.response!.data.toString();
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  Future<Map<String, dynamic>> getInstitutionInfo() async {
    try {
      final response = await _dio.get('/api/v1/institution/info');

      if (response.statusCode == 200) {
        return {'success': true, 'institution': response.data};
      }
      return {'success': false, 'error': 'Failed to fetch institution info'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  Future<Map<String, dynamic>> getGraduateCredential(
    String credentialId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/graduate/credentials/$credentialId',
      );

      print('Get graduate credential response status: ${response.statusCode}');
      print('Get graduate credential response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'studentId': data['student_id'],
          'studentName': data['student_name'],
          'degree': data['degree'],
          'institution': data['institution'],
          'graduationDate': data['graduation_date'],
          'issuedAt': data['issued_at'],
          'status': data['status'],
        };
      }
      return {'success': false, 'error': 'Failed to fetch credential'};
    } on DioException catch (e) {
      print('Get graduate credential error: ${e.response?.data}');

      String errorMessage = 'Network error';
      if (e.response?.statusCode == 404) {
        errorMessage = 'Credential not found';
      } else if (e.response?.statusCode == 403) {
        errorMessage = 'You do not have permission to view this credential';
      } else if (e.response?.data != null) {
        errorMessage =
            e.response!.data['message'] ?? e.response!.data.toString();
      }

      return {'success': false, 'error': errorMessage};
    }
  }

  Future<List<Map<String, dynamic>>> getGraduateCredentials() async {
    try {
      final response = await _dio.get('/api/v1/graduate/credentials');

      print('Get graduate credentials response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      print('Error fetching graduate credentials: ${e.message}');
      return [];
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
