class Dashboard {
  const Dashboard({
    this.vehiclesCount,
    this.activeBookings,
    this.activeServiceOrders,
    this.pendingPayments,
    this.unreadNotifications,
    this.recentBookings,
    this.latestDelivery,
    this.assignedTotal,
    this.pending,
    this.inProgress,
    this.completed,
    this.activeOrders,
    this.pickupTotal,
    this.deliveryTotal,
    this.activeTotal,
    this.completedTotal,
    this.activeTasks,
    this.data,
  });

  final int? vehiclesCount;
  final int? activeBookings;
  final int? activeServiceOrders;
  final int? pendingPayments;
  final int? unreadNotifications;

  final List<dynamic>? recentBookings;
  final Map<String, dynamic>? latestDelivery;

  final int? assignedTotal;
  final int? pending;
  final int? inProgress;
  final int? completed;
  final List<dynamic>? activeOrders;

  final int? pickupTotal;
  final int? deliveryTotal;
  final int? activeTotal;
  final int? completedTotal;
  final List<dynamic>? activeTasks;

  final Map<String, dynamic>? data;

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    return Dashboard(
      vehiclesCount: _toInt(json['vehicles_count']),
      activeBookings: _toInt(json['active_bookings']),
      activeServiceOrders: _toInt(json['active_service_orders']),
      pendingPayments: _toInt(json['pending_payments']),
      unreadNotifications: _toInt(json['unread_notifications']),
      recentBookings: _toList(json['recent_bookings']),
      latestDelivery: _toMap(json['latest_delivery']),
      assignedTotal: _toInt(json['assigned_total']),
      pending: _toInt(json['pending']),
      inProgress: _toInt(json['in_progress']),
      completed: _toInt(json['completed']),
      activeOrders: _toList(json['active_orders']),
      pickupTotal: _toInt(json['pickup_total']),
      deliveryTotal: _toInt(json['delivery_total']),
      activeTotal: _toInt(json['active_total']),
      completedTotal: _toInt(json['completed_total']),
      activeTasks: _toList(json['active_tasks']),
      data: _toMap(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicles_count': vehiclesCount,
      'active_bookings': activeBookings,
      'active_service_orders': activeServiceOrders,
      'pending_payments': pendingPayments,
      'unread_notifications': unreadNotifications,
      'recent_bookings': recentBookings,
      'latest_delivery': latestDelivery,
      'assigned_total': assignedTotal,
      'pending': pending,
      'in_progress': inProgress,
      'completed': completed,
      'active_orders': activeOrders,
      'pickup_total': pickupTotal,
      'delivery_total': deliveryTotal,
      'active_total': activeTotal,
      'completed_total': completedTotal,
      'active_tasks': activeTasks,
      'data': data,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static List<dynamic>? _toList(dynamic value) {
    if (value is List) {
      return List<dynamic>.from(value);
    }

    return null;
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }
}
