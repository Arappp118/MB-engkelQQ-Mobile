import 'service_order_item.dart';

class ServiceOrder {
  const ServiceOrder({
    required this.id,
    this.bookingId,
    this.customerId,
    this.mechanicId,
    this.status,
    this.subtotal,
    this.deliveryFee,
    this.grandTotal,
    this.diagnosis,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.items = const [],
  });

  final int id;
  final int? bookingId;
  final int? customerId;
  final int? mechanicId;
  final String? status;
  final double? subtotal;
  final double? deliveryFee;
  final double? grandTotal;
  final String? diagnosis;
  final String? notes;
  final String? startedAt;
  final String? completedAt;
  final List<ServiceOrderItem> items;

  factory ServiceOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return ServiceOrder(
      id: _toInt(json['id']) ?? 0,

      bookingId: _toInt(json['booking_id']),

      customerId: _toInt(json['customer_id']),

      mechanicId: _toInt(json['mechanic_id']),

      status: json['status']?.toString(),

      subtotal: _toDouble(json['subtotal']),

      deliveryFee: _toDouble(json['delivery_fee']),

      grandTotal: _toDouble(json['grand_total']),

      // Backend menggunakan diagnosis_mechanic.
      diagnosis: json['diagnosis_mechanic']?.toString(),

      notes: json['notes']?.toString(),

      startedAt: json['started_at']?.toString(),

      completedAt: json['completed_at']?.toString(),

      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => ServiceOrderItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'customer_id': customerId,
      'mechanic_id': mechanicId,
      'status': status,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'grand_total': grandTotal,
      'diagnosis_mechanic': diagnosis,
      'notes': notes,
      'started_at': startedAt,
      'completed_at': completedAt,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
