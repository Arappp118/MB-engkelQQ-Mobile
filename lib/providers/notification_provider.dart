import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  List<AppNotification> _notifications = [];
  List<AppNotification> _unreadNotifications = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<AppNotification> get unreadNotifications =>
      List.unmodifiable(_unreadNotifications);

  int get unreadCount {
    if (_unreadNotifications.isNotEmpty) {
      return _unreadNotifications.length;
    }
    return _notifications.where((item) => !item.isReadStatus).length;
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadNotifications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _notifications = await _notificationService.getNotifications();
      _syncUnreadFromNotifications();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadUnreadNotifications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _unreadNotifications = await _notificationService
          .getUnreadNotifications();

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markAsRead(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final notification = await _notificationService.markAsRead(id);

      _notifications = _notifications
          .map((item) => item.id == id ? notification : item)
          .toList();

      _unreadNotifications = _unreadNotifications
          .where((item) => item.id != id)
          .toList();

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAllAsRead() async {
    final toMark = _notifications
        .where((n) => !n.isReadStatus)
        .map((n) => n.id)
        .toList();

    if (toMark.isEmpty && _unreadNotifications.isNotEmpty) {
      toMark.addAll(_unreadNotifications.map((n) => n.id));
    }

    for (final id in toMark) {
      try {
        final updated = await _notificationService.markAsRead(id);
        _notifications = _notifications
            .map((item) => item.id == id ? updated : item)
            .toList();
      } catch (_) {
        // continue best-effort
      }
    }
    _unreadNotifications = [];
    notifyListeners();
  }

  void _syncUnreadFromNotifications() {
    _unreadNotifications = _notifications
        .where((item) => !item.isReadStatus)
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications = [];
    _unreadNotifications = [];
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return ApiException.extractMessage(error);
  }
}
