// import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
// import 'package:flutter/foundation.dart';
// import '../models/certificate.dart';
import '../models/user.dart';
import 'storage_service.dart';

class ApiService {
  static const String baseUrl =
      'https://academic-credential-verification.onrender.com';

  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // ignore: deprecated_member_use
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
          log('REQUEST: ${options.method} ${options.path}');
          log('HEADERS: ${options.headers}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log('RESPONSE: ${response.statusCode}');
          log('RESPONSE DATA: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          log('ERROR: ${error.response?.statusCode} - ${error.message}');
          log('ERROR TYPE: ${error.type}');

          if (error.response?.statusCode == 307 ||
              error.response?.statusCode == 302) {
            final location = error.response?.headers['location']?.first;
            if (location != null) {
              log('Redirecting to: $location');
              try {
                final response = await _dio.get(location);
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

  /// Login with email and password
  /// Supports: institution_admin, external_verifier, graduate
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      log('Attempting login to: $baseUrl/api/v1/auth/login');
      log('Email: $email');

      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );

      log('Login response status: ${response.statusCode}');
      log('Login response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await StorageService.saveAuthToken(data['access_token']);
        await StorageService.saveRefreshToken(data['refresh_token']);
        await StorageService.saveTokenType(data['token_type']);
        await StorageService.setTokenExpiry(data['expires_in']);

        // Extract user data
        final userData = data['user'];

        final String userId = userData['user_id'];
        final String userEmail = userData['email'];
        final String userRole = userData['role'];
        final String? fullName = userData['full_name'];
        final String? institutionId = userData['institution_id'];
        final String? institutionName = userData['institution_name'];
        final String? studentId = userData['student_id'];

        // Map role to UserRole enum
        UserRole role;
        switch (userRole) {
          case 'institution_admin':
            role = UserRole.institutionAdmin;
            break;
          case 'external_verifier':
            role = UserRole.verifier;
            break;
          case 'graduate':
            role = UserRole.student;
            break;
          default:
            role = UserRole.verifier;
        }

        // Determine display name
        String displayName;
        if (fullName != null && fullName.isNotEmpty) {
          displayName = fullName;
        } else if (institutionName != null && institutionName.isNotEmpty) {
          displayName = institutionName;
        } else if (studentId != null && studentId.isNotEmpty) {
          displayName = studentId;
        } else {
          displayName = userEmail.split('@')[0];
        }

        // Create user object
        final user = User(
          id: userId,
          name: displayName,
          email: userEmail,
          role: role,
          institutionId: institutionId,
          institutionName: institutionName,
          studentId: studentId,
          createdAt: DateTime.now(),
        );

        // Save user to storage
        await StorageService.saveUser(user.toJson());

        return {
          'success': true,
          'user': user,
          'accessToken': data['access_token'],
          'refreshToken': data['refresh_token'],
          'tokenType': data['token_type'],
          'expiresIn': data['expires_in'],
        };
      }

      return {
        'success': false,
        'error':
            response.data['message'] ??
            'Login failed with status ${response.statusCode}',
      };
    } on DioException catch (e) {
      log('Login DioException: ${e.type}');
      log('Login error message: ${e.message}');
      log('Login error response: ${e.response?.data}');

      String errorMessage = 'Network error. Please check your connection.';

      if (e.response?.statusCode == 307) {
        errorMessage = 'Redirect error. Please ensure you are using HTTPS.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid email or password.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Login service not found. Please try again later.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please try again.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Server timeout. The service might be waking up. Please try again in 30 seconds.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map) {
          errorMessage =
              e.response!.data['message'] ??
              e.response!.data['error'] ??
              'Login failed';
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data;
        } else {
          errorMessage = 'Login failed';
        }
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      log('Login unexpected error: $e');
      return {'success': false, 'error': e.toString()};
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

  // ==================== REGISTRATION ====================

  /// Register a new Institution Admin
  Future<Map<String, dynamic>> registerInstitution({
    required String email,
    required String password,
    required String confirmPassword,
    required String institutionName,
    required String institutionCode,
    required String address,
    required String contactEmail,
    required String contactPhone,
    required String adminName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/institution/register',
        data: {
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'institution_name': institutionName,
          'institution_code': institutionCode,
          'address': address,
          'contact_email': contactEmail,
          'contact_phone': contactPhone,
          'admin_name': adminName,
        },
      );

      log('Institution registration response: ${response.statusCode}');
      log('Institution registration data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'userId': data['user_id'],
          'email': data['email'],
          'institutionId': data['institution_id'],
          'institutionName': data['institution_name'],
          'institutionCode': data['institution_code'],
          'role': data['role'],
          'message': data['message'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Registration failed',
      };
    } on DioException catch (e) {
      log('Institution registration error: ${e.response?.data}');
      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Network error';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Register a new External Verifier
  Future<Map<String, dynamic>> registerVerifier({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String organization,
    required String contactPhone,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/verifier/register',
        data: {
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'name': name,
          'organization': organization,
          'contact_phone': contactPhone,
        },
      );

      log('Verifier registration response: ${response.statusCode}');
      log('Verifier registration data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'userId': data['user_id'],
          'email': data['email'],
          'name': data['name'],
          'organization': data['organization'],
          'role': data['role'],
          'message': data['message'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Registration failed',
      };
    } on DioException catch (e) {
      log('Verifier registration error: ${e.response?.data}');
      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Network error';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Register a new Graduate Student
  Future<Map<String, dynamic>> registerGraduate({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String studentId,
    required String institutionCode,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/graduate/register',
        data: {
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
          'full_name': fullName,
          'student_id': studentId,
          'institution_code': institutionCode,
        },
      );

      log('Graduate registration response: ${response.statusCode}');
      log('Graduate registration data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'userId': data['user_id'],
          'email': data['email'],
          'fullName': data['student_name'] ?? fullName,
          'studentId': data['student_id'],
          'studentName': data['student_name'],
          'graduationDate': data['graduation_date'],
          'institutionName': data['institution_name'],
          'role': data['role'],
          'message': data['message'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Registration failed',
      };
    } on DioException catch (e) {
      log('Graduate registration error: ${e.response?.data}');

      // Handle specific error for student not found
      if (e.response?.statusCode == 404 ||
          e.response?.data['code'] == 'STUDENT_NOT_FOUND') {
        return {
          'success': false,
          'error':
              'No credential found for the provided Student ID. Please contact your institution.',
          'code': 'STUDENT_NOT_FOUND',
        };
      }

      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Network error';
      return {'success': false, 'error': errorMessage};
    }
  }
  // // ==================== CERTIFICATE OPERATIONS ====================

  /// Check credential status
  Future<Map<String, dynamic>> checkCredentialStatus(
    String credentialId,
  ) async {
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
          'checkedAt': data['checked_at'],
          'isValid': data['status'] == 'active',
        };
      }
      return {'success': false, 'error': 'Failed to check status'};
    } on DioException catch (e) {
      log('Check status error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Verify a credential
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

  /// Get user's own credentials
  Future<List<Map<String, dynamic>>> getUserCredentials() async {
    try {
      final response = await _dio.get('/api/v1/user/credentials');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      log('Error fetching user credentials: ${e.message}');
      return [];
    }
  }

  /// Get graduate's specific credential
  // ==================== GRADUATE CREDENTIAL OPERATIONS ====================

  /// Get graduate's specific credential details
  Future<Map<String, dynamic>> getGraduateCredential(
    String credentialId,
  ) async {
    try {
      final response = await _dio.get(
        '/api/v1/graduate/credentials/$credentialId',
      );

      print('Get graduate credential response: ${response.statusCode}');
      print('Get graduate credential data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'checkedAt': data['checked_at'],
          'issuedAt': data['issued_at'],
          'status': data['status'],
          'isValid': data['status'] == 'active',
        };
      }
      return {'success': false, 'error': 'Credential not found'};
    } on DioException catch (e) {
      print('Get graduate credential error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Get all credentials for a graduate student
  Future<Map<String, dynamic>> getGraduateCredentials() async {
    try {
      final response = await _dio.get('/api/v1/graduate/credentials');

      print('Get graduate credentials response: ${response.statusCode}');
      print('Get graduate credentials data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentials': data['credentials'],
          'studentId': data['student_id'],
          'total': data['total'],
        };
      }
      return {'success': false, 'error': 'Failed to fetch credentials'};
    } on DioException catch (e) {
      print('Get graduate credentials error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  // ==================== INSTITUTION OPERATIONS ====================

  /// Get institution information
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

  // ==================== CREDENTIAL OPERATIONS ====================

  /// Issue a new certificate (Institution Admin only)
  Future<Map<String, dynamic>> issueCertificate({
    required String studentId,
    required String studentName,
    required String institutionCode,
    required String degree,
    required String graduationDate,
    required String issuerDigitalSignature,
    List<String>? skills,
    String? cgpa,
  }) async {
    try {
      final requestBody = {
        'student_id': studentId,
        'student_name': studentName,
        'institution_code': institutionCode,
        'degree': degree,
        'graduation_date': graduationDate,
        'issuer_digital_signature': issuerDigitalSignature,
        if (skills != null && skills.isNotEmpty) 'skills': skills,
        if (cgpa != null && cgpa.isNotEmpty) 'cgpa': cgpa,
      };

      log('Issue certificate request body: $requestBody');

      final response = await _dio.post(
        '/api/v1/institution/credentials/issue',
        data: requestBody,
      );

      log('Issue certificate response status: ${response.statusCode}');
      log('Issue certificate response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'transactionId': data['tx_id'],
          'qrCodeBase64': data['qr_code_base64'],
          'qrPayload': data['qr_payload'],
          'issuedAt': data['issued_at'],
          'issuedBy': data['issued_by'],
          'studentId': data['student_id'],
          'studentName': data['student_name'],
          'degree': data['degree'],
          'graduationDate': data['graduation_date'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to issue certificate',
      };
    } on DioException catch (e) {
      log('Issue certificate error: ${e.response?.data}');
      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Network error';
      return {'success': false, 'error': errorMessage};
    }
  }

  /// Get credential details by ID
  Future<Map<String, dynamic>> getCredentialDetails(String credentialId) async {
    try {
      final response = await _dio.get(
        '/api/v1/institution/credentials/$credentialId',
      );

      log('Get credential details response: ${response.statusCode}');
      log('Get credential details data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final credential = data['credential'] ?? data;
        return {
          'success': true,
          'credentialId': credential['credential_id'],
          'studentId': credential['student_id'],
          'studentName': credential['student_name'],
          'studentDob': credential['student_dob'],
          'degree': credential['degree'],
          'degreeClass': credential['degree_class'],
          'cgpa': credential['cgpa'],
          'graduationDate': credential['graduation_date'],
          'institutionId': credential['institution_id'],
          'institutionName': credential['institution_name'],
          'issuedAt': credential['issued_at'],
          'issuedBy': credential['issued_by'],
          'status': credential['status'],
        };
      }
      return {'success': false, 'error': 'Credential not found'};
    } on DioException catch (e) {
      log('Get credential details error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Revoke a credential (Institution Admin only)
  Future<Map<String, dynamic>> revokeCredential({
    required String credentialId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/institution/credentials/revoke',
        data: {'credential_id': credentialId, 'reason': reason},
      );

      log('Revoke credential response: ${response.statusCode}');
      log('Revoke credential data: ${response.data}');

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
      log('Revoke credential error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Suspend a credential (Institution Admin only)
  Future<Map<String, dynamic>> suspendCredential({
    required String credentialId,
    required String reason,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/institution/credentials/suspend',
        data: {'credential_id': credentialId, 'reason': reason},
      );

      log('Suspend credential response: ${response.statusCode}');
      log('Suspend credential data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'message': data['message'],
          'reason': data['reason'],
          'suspendedAt': data['suspended_at'],
          'suspendedBy': data['suspended_by'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to suspend credential',
      };
    } on DioException catch (e) {
      log('Suspend credential error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Reinstate a credential (Institution Admin only)
  Future<Map<String, dynamic>> reinstateCredential({
    required String credentialId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/institution/credentials/reinstate',
        data: {'credential_id': credentialId},
      );

      log('Reinstate credential response: ${response.statusCode}');
      log('Reinstate credential data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentialId': data['credential_id'],
          'message': data['message'],
          'reinstatedAt': data['reinstated_at'],
          'reinstatedBy': data['reinstated_by'],
        };
      }
      return {
        'success': false,
        'error': response.data['message'] ?? 'Failed to reinstate credential',
      };
    } on DioException catch (e) {
      log('Reinstate credential error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  /// Get institution credentials (for Institution Admins)
  Future<Map<String, dynamic>> getInstitutionCredentials({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/api/v1/institution/credentials',
        queryParameters: {'page': page, 'limit': limit},
      );

      print('Get institution credentials response: ${response.statusCode}');
      print('Get institution credentials data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'credentials': data['credentials'] ?? [], // Handle null case
          'pagination':
              data['pagination'] ??
              {'limit': limit, 'page': page, 'total': 0, 'total_pages': 0},
        };
      }
      return {'success': false, 'error': 'Failed to fetch credentials'};
    } on DioException catch (e) {
      print('Get institution credentials error: ${e.response?.data}');
      return {
        'success': false,
        'error': e.response?.data['message'] ?? 'Network error',
      };
    }
  }

  // ==================== HEALTH CHECK ====================

  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
