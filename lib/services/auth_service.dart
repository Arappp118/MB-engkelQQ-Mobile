import 'dart:convert';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, SecureStorage? storage})
    : _apiClient = apiClient ?? ApiClient(),
      _storage = storage ?? SecureStorage.instance;

  final ApiClient _apiClient;
  final SecureStorage _storage;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response login tidak memiliki format data yang valid.',
      );
    }

    final dataMap = Map<String, dynamic>.from(data);

    final token = dataMap['token'];

    if (token is! String || token.isEmpty) {
      throw const FormatException('Token login tidak ditemukan pada response.');
    }

    await _storage.saveToken(token);

    final user = dataMap['user'];

    if (user is Map) {
      await _storage.saveUser(jsonEncode(Map<String, dynamic>.from(user)));
    }

    return dataMap;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _apiClient.get(ApiConstants.me);

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response user tidak memiliki format data yang valid.',
      );
    }

    final user = Map<String, dynamic>.from(data);

    await _storage.saveUser(jsonEncode(user));

    return user;
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } finally {
      await _storage.clearAuth();
    }
  }

  Future<String?> getStoredToken() {
    return _storage.getToken();
  }

  Future<String?> getStoredUser() {
    return _storage.getUser();
  }

  Future<void> clearSession() {
    return _storage.clearAuth();
  }
}
