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
    this.totalCustomers,
    this.totalVehicles,
    this.totalBookings,
    this.totalServiceOrders,
    this.paymentPending,
    this.paymentVerified,
    this.deliveryTaskTotal,
    this.invoiceTotal,
    this.mechanicTotal,
    this.courierTotal,
    this.serviceItemTotal,
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

  // Admin operational metrics
  final int? totalCustomers;
  final int? totalVehicles;
  final int? totalBookings;
  final int? totalServiceOrders;
  final int? paymentPending;
  final int? paymentVerified;
  final int? deliveryTaskTotal;
  final int? invoiceTotal;
  final int? mechanicTotal;
  final int? courierTotal;
  final int? serviceItemTotal;

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
      totalCustomers: _toInt(json['total_customers']),
      totalVehicles: _toInt(json['total_vehicles']),
      totalBookings: _toInt(json['total_bookings']),
      totalServiceOrders: _toInt(json['total_service_orders']),
      paymentPending: _toInt(json['payment_pending']),
      paymentVerified: _toInt(json['payment_verified']),
      deliveryTaskTotal: _toInt(json['delivery_task_total']),
      invoiceTotal: _toInt(json['invoice_total']),
      mechanicTotal: _toInt(json['mechanic_total']),
      courierTotal: _toInt(json['courier_total']),
      serviceItemTotal: _toInt(json['service_item_total']),
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
      'total_customers': totalCustomers,
      'total_vehicles': totalVehicles,
      'total_bookings': totalBookings,
      'total_service_orders': totalServiceOrders,
      'payment_pending': paymentPending,
      'payment_verified': paymentVerified,
      'delivery_task_total': deliveryTaskTotal,
      'invoice_total': invoiceTotal,
      'mechanic_total': mechanicTotal,
      'courier_total': courierTotal,
      'service_item_total': serviceItemTotal,
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
