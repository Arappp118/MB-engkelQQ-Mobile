import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

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

  Future<void> clearAuth() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userKey);
  }
}
