import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static SecureStorage instance = SecureStorage();

  final FlutterSecureStorage _storage;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String baseUrlKey = 'api_base_url';

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: tokenKey);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return _storage.read(key: userKey);
  }

  Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: baseUrlKey, value: url);
  }

  Future<String?> getBaseUrl() async {
    return _storage.read(key: baseUrlKey);
  }

  Future<void> clearBaseUrl() async {
    await _storage.delete(key: baseUrlKey);
  }

  Future<void> clearAuth() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
  }
}
