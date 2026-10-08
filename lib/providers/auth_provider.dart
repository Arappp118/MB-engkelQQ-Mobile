import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;

  bool get isAuthenticated => _user != null;

  String? get role {
    final value = _user?['role'];

    if (value is String && value.isNotEmpty) {
      return value;
    }

    return null;
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final data = await _authService.login(email: email, password: password);

      final user = data['user'];

      if (user is Map) {
        _user = Map<String, dynamic>.from(user);
      } else {
        await loadCurrentUser();
      }

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadCurrentUser() async {
    try {
      final storedUser = await _authService.getStoredUser();

      if (storedUser != null && storedUser.isNotEmpty) {
        final decoded = jsonDecode(storedUser);

        if (decoded is Map) {
          _user = Map<String, dynamic>.from(decoded);
          notifyListeners();
          return true;
        }
      }

      final user = await _authService.getMe();
      _user = user;

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      _user = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.logout();
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
    } finally {
      _user = null;
      _setLoading(false);
    }
  }

  Future<bool> hasSession() async {
    final token = await _authService.getStoredToken();

    return token != null && token.isNotEmpty;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}
