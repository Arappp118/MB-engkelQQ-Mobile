import 'package:flutter/foundation.dart';

import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? dashboardService})
    : _dashboardService = dashboardService ?? DashboardService();

  final DashboardService _dashboardService;

  Dashboard? _dashboard;
  bool _isLoading = false;
  String? _errorMessage;

  Dashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadDashboard() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _dashboard = await _dashboardService.getDashboard();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearDashboard() {
    _dashboard = null;
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
