import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static late Box _certificatesBox;
  static late Box _userBox;
  static late SharedPreferences _prefs;

  static const String _userKey = 'user';
  static const String _authTokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  static Future<void> init() async {
    // Initialize Hive boxes
    _certificatesBox = await Hive.openBox('certificates');
    _userBox = await Hive.openBox('user_data');

    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== USER STORAGE ====================

  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _userBox.put('current_user', userData);
    await _prefs.setBool(_isLoggedInKey, true);
  }

  static Map<String, dynamic>? getUser() {
    final user = _userBox.get('current_user');
    return user != null ? Map<String, dynamic>.from(user) : null;
  }

  static Future<void> saveAuthToken(String token) async {
    await _prefs.setString(_authTokenKey, token);
  }

  static String? getAuthToken() {
    return _prefs.getString(_authTokenKey);
  }

  static bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // ==================== CERTIFICATE STORAGE (Offline Cache) ====================

  static Future<void> saveCertificate(Map<String, dynamic> certificate) async {
    final id = certificate['transactionId'] ?? certificate['id'];
    await _certificatesBox.put(id, certificate);
  }

  static Map<String, dynamic>? getCertificate(String transactionId) {
    final cert = _certificatesBox.get(transactionId);
    return cert != null ? Map<String, dynamic>.from(cert) : null;
  }

  static List<Map<String, dynamic>> getAllCertificates() {
    return _certificatesBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> deleteCertificate(String transactionId) async {
    await _certificatesBox.delete(transactionId);
  }

  static Future<void> clearAllCertificates() async {
    await _certificatesBox.clear();
  }

  // ==================== RECENT VERIFICATIONS ====================

  static Future<void> saveRecentVerification(String transactionId) async {
    List<String> recents = _prefs.getStringList('recent_verifications') ?? [];
    recents.remove(transactionId);
    recents.insert(0, transactionId);
    if (recents.length > 20) recents.removeLast();
    await _prefs.setStringList('recent_verifications', recents);
  }

  static List<String> getRecentVerifications() {
    return _prefs.getStringList('recent_verifications') ?? [];
  }

  // ==================== OFFLINE SYNC STATUS ====================

  static Future<void> setLastSyncTime(DateTime time) async {
    await _prefs.setString('last_sync', time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final timeStr = _prefs.getString('last_sync');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  static Future<void> setPendingSyncCount(int count) async {
    await _prefs.setInt('pending_sync', count);
  }

  static int getPendingSyncCount() {
    return _prefs.getInt('pending_sync') ?? 0;
  }

  // ==================== USER SETTINGS ====================

  static Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool('biometric_enabled', enabled);
  }

  static bool isBiometricEnabled() {
    return _prefs.getBool('biometric_enabled') ?? false;
  }

  static Future<void> setDarkModeEnabled(bool enabled) async {
    await _prefs.setBool('dark_mode', enabled);
  }

  static bool isDarkModeEnabled() {
    return _prefs.getBool('dark_mode') ?? false;
  }

  static Future<void> setLanguage(String languageCode) async {
    await _prefs.setString('language', languageCode);
  }

  static String getLanguage() {
    return _prefs.getString('language') ?? 'en';
  }

  // ==================== CLEAR ALL DATA ====================

  static Future<void> clear() async {
    await _userBox.clear();
    await _certificatesBox.clear();
    await _prefs.clear();
  }

  // Add these methods to your existing StorageService class

  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _tokenExpiryKey = 'token_expiry';

  static Future<void> saveRefreshToken(String token) async {
    await _prefs.setString(_refreshTokenKey, token);
  }

  static String? getRefreshToken() {
    return _prefs.getString(_refreshTokenKey);
  }

  static Future<void> saveTokenType(String tokenType) async {
    await _prefs.setString(_tokenTypeKey, tokenType);
  }

  static String? getTokenType() {
    return _prefs.getString(_tokenTypeKey);
  }

  static Future<void> setTokenExpiry(int expiresIn) async {
    final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));
    await _prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());
  }

  static bool isTokenExpired() {
    final expiryStr = _prefs.getString(_tokenExpiryKey);
    if (expiryStr == null) return true;
    final expiryTime = DateTime.parse(expiryStr);
    return DateTime.now().isAfter(expiryTime);
  }
}
