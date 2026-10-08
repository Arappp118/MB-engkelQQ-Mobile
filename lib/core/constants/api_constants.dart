class ApiConstants {
  ApiConstants._();

  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // ============================================================
  // AUTH
  // ============================================================

  static const String login = '/auth/login';

  static const String logout = '/auth/logout';

  static const String me = '/auth/me';

  // ============================================================
  // DASHBOARD
  // ============================================================

  static const String dashboard = '/dashboard';

  // ============================================================
  // VEHICLES
  // ============================================================

  static const String vehicles = '/vehicles';

  // ============================================================
  // BOOKINGS
  // ============================================================

  static const String bookings = '/bookings';

  // ============================================================
  // DELIVERY TASKS
  // ============================================================

  static const String deliveryTasks = '/delivery-tasks';

  // ============================================================
  // SERVICE ORDERS
  // ============================================================

  static const String serviceOrders = '/service-orders';

  // ============================================================
  // SERVICE ITEMS
  // ============================================================

  static const String serviceItems = '/service-items';

  // ============================================================
  // PAYMENTS
  // ============================================================

  static const String payments = '/payments';

  // ============================================================
  // INVOICES
  // ============================================================

  static const String invoices = '/invoices';

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  static const String notifications = '/notifications';

  static const String unreadNotifications = '/notifications/unread';

  // ============================================================
  // NETWORK TIMEOUT
  // ============================================================

  static const Duration connectTimeout = Duration(seconds: 15);

  static const Duration receiveTimeout = Duration(seconds: 15);
}
