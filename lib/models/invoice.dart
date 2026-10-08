class InvoiceItem {
  const InvoiceItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']) ?? 0.0,
      quantity: _toInt(json['quantity']) ?? 1,
      subtotal: _toDouble(json['subtotal']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
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

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}

class Invoice {
  const Invoice({
    required this.invoiceNumber,
    this.serviceOrderId,
    this.nomorBooking,
    this.tanggal,
    this.customer,
    this.vehicle,
    this.items = const [],
    this.subtotal,
    this.deliveryFee,
    this.grandTotal,
    this.paymentStatus,
    this.paymentMethod,
  });

  final String invoiceNumber;
  final int? serviceOrderId;
  final String? nomorBooking;
  final String? tanggal;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? vehicle;
  final List<InvoiceItem> items;
  final double? subtotal;
  final double? deliveryFee;
  final double? grandTotal;
  final String? paymentStatus;
  final String? paymentMethod;

  String? get customerName => customer?['name']?.toString();
  String? get customerEmail => customer?['email']?.toString();
  String? get vehiclePlate => vehicle?['nomor_polisi']?.toString();
  String? get vehicleMerk => vehicle?['merk']?.toString();
  String? get vehicleModel => vehicle?['model']?.toString();

  Invoice copyWith({
    String? invoiceNumber,
    int? serviceOrderId,
    String? nomorBooking,
    String? tanggal,
    Map<String, dynamic>? customer,
    Map<String, dynamic>? vehicle,
    List<InvoiceItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? grandTotal,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return Invoice(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      serviceOrderId: serviceOrderId ?? this.serviceOrderId,
      nomorBooking: nomorBooking ?? this.nomorBooking,
      tanggal: tanggal ?? this.tanggal,
      customer: customer ?? this.customer,
      vehicle: vehicle ?? this.vehicle,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final parsedItems = <InvoiceItem>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(
            InvoiceItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    return Invoice(
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      serviceOrderId: _toInt(json['service_order_id']),
      nomorBooking: json['nomor_booking']?.toString(),
      tanggal: json['tanggal']?.toString(),
      customer: _toMap(json['customer']),
      vehicle: _toMap(json['vehicle']),
      items: parsedItems,
      subtotal: _toDouble(json['subtotal']),
      deliveryFee: _toDouble(json['delivery_fee']),
      grandTotal: _toDouble(json['grand_total']),
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice_number': invoiceNumber,
      'service_order_id': serviceOrderId,
      'nomor_booking': nomorBooking,
      'tanggal': tanggal,
      'customer': customer,
      'vehicle': vehicle,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'grand_total': grandTotal,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
    };
  }

  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
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
