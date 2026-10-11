class DeliveryTask {
  const DeliveryTask({
    required this.id,
    this.bookingId,
    this.courierId,
    this.courierName,
    this.type,
    this.status,
    this.pickupAddress,
    this.address,
    this.distanceKm,
    this.deliveryFee,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  final int id;
  final int? bookingId;
  final int? courierId;
  final String? courierName;
  final String? type;
  final String? status;
  final String? pickupAddress;
  final String? address;
  final double? distanceKm;
  final double? deliveryFee;
  final String? startedAt;
  final String? completedAt;
  final String? notes;

  static String cleanAddress(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final segments = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final uniqueSegments = <String>[];

    String normalize(String text) {
      var t = text.toLowerCase();
      const replacements = [
        ('kecamatan', 'kec.'),
        ('kelurahan', 'kel.'),
        ('kabupaten', 'kab.'),
        ('timur', 'tim.'),
        ('barat', 'bar.'),
        ('selatan', 'sel.'),
        ('utara', 'ut.'),
      ];
      for (final r in replacements) {
        t = t.replaceAll(r.$1, r.$2);
      }
      return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
    }

    for (final seg in segments) {
      final normSeg = normalize(seg);
      var isDup = false;
      for (final ex in uniqueSegments) {
        final normEx = normalize(ex);
        if (normSeg == normEx ||
            (normSeg.length > 4 && normEx.contains(normSeg)) ||
            (normEx.length > 4 && normSeg.contains(normEx))) {
          isDup = true;
          break;
        }
      }
      if (!isDup) {
        uniqueSegments.add(seg);
      }
    }
    return uniqueSegments.isEmpty ? '-' : uniqueSegments.join(', ');
  }

  String? get rawAddress => address ?? pickupAddress;

  String? get resolvedAddress {
    final raw = address ?? pickupAddress;
    if (raw == null) return null;
    return cleanAddress(raw);
  }

  String get compactAddress {
    final clean = resolvedAddress;
    if (clean == null || clean == '-') return '-';
    final parts = clean
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length <= 2) return clean;
    return '${parts.take(2).join(', ')}...';
  }

  String get courierDisplay {
    if (courierName != null && courierName!.trim().isNotEmpty) {
      return courierName!.trim();
    }
    if (courierId != null) {
      return 'Kurir #$courierId';
    }
    return 'Belum ditugaskan';
  }

  factory DeliveryTask.fromJson(Map<String, dynamic> json) {
    final addr = (json['address'] ?? json['pickup_address'])?.toString();
    final courierObj = json['courier'];
    String? courierName;
    if (courierObj is Map) {
      courierName = courierObj['name']?.toString();
    } else if (json['courier_name'] != null) {
      courierName = json['courier_name']?.toString();
    }

    return DeliveryTask(
      id: _toInt(json['id']) ?? 0,
      bookingId: _toInt(json['booking_id']),
      courierId: _toInt(json['courier_id']),
      courierName: courierName != null && courierName.trim().isNotEmpty
          ? courierName.trim()
          : null,
      type: (json['type'] ?? json['task_type'])?.toString(),
      status: json['status']?.toString(),
      pickupAddress: addr,
      address: addr,
      distanceKm: _toDouble(json['distance_km']),
      deliveryFee: _toDouble(json['delivery_fee']),
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'courier_id': courierId,
      if (courierName != null) 'courier_name': courierName,
      'type': type,
      'status': status,
      'address': address ?? pickupAddress,
      'pickup_address': pickupAddress ?? address,
      'distance_km': distanceKm,
      'delivery_fee': deliveryFee,
      'started_at': startedAt,
      'completed_at': completedAt,
      'notes': notes,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
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
