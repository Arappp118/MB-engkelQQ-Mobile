class DeliveryTask {
  const DeliveryTask({
    required this.id,
    this.bookingId,
    this.courierId,
    this.type,
    this.status,
    this.pickupAddress,
    this.notes,
  });

  final int id;
  final int? bookingId;
  final int? courierId;
  final String? type;
  final String? status;
  final String? pickupAddress;
  final String? notes;

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    return DeliveryTask(
      id: _toInt(json['id']) ?? 0,
      bookingId: _toInt(json['booking_id']),
      courierId: _toInt(json['courier_id']),
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'courier_id': courierId,
      'type': type,
      'status': status,
      'pickup_address': pickupAddress,
      'notes': notes,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }
}
