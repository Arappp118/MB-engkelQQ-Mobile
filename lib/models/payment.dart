class Payment {
  const Payment({
    required this.id,
    this.serviceOrderId,
    this.amount,
    this.method,
    this.status,
    this.proofUrl,
    this.hasProof,
    this.paidAt,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? serviceOrderId;
  final double? amount;
  final String? method;
  final String? status;
  final String? proofUrl;
  final bool? hasProof;
  final String? paidAt;
  final int? verifiedBy;
  final String? verifiedAt;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: _toInt(json['id']) ?? 0,
      serviceOrderId: _toInt(json['service_order_id']),
      amount: _toDouble(json['amount']),
      method: (json['payment_method'] ?? json['method'])?.toString(),
      status: json['status']?.toString(),
      proofUrl: json['proof_url']?.toString(),
      hasProof: _toBool(json['has_proof']) ?? (json['proof_url'] != null),
      paidAt: json['paid_at']?.toString(),
      verifiedBy: _toInt(json['verified_by']),
      verifiedAt: json['verified_at']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_order_id': serviceOrderId,
      'amount': amount,
      'payment_method': method,
      'method': method,
      'status': status,
      'proof_url': proofUrl,
      'has_proof': hasProof,
      'paid_at': paidAt,
      'verified_by': verifiedBy,
      'verified_at': verifiedAt,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get methodLabel {
    switch (method?.toLowerCase()) {
      case 'cash':
        return 'Tunai (Cash)';
      case 'transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return method ?? '-';
    }
  }

  String get statusLabel {
    switch (status?.toLowerCase()) {
      case 'waiting_verification':
        return 'Menunggu Verifikasi';
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      case 'paid':
        return 'Lunas';
      case 'pending':
        return 'Menunggu';
      default:
        return status ?? '-';
    }
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

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value == 1 || value == '1' || value == 'true') {
      return true;
    }
    if (value == 0 || value == '0' || value == 'false') {
      return false;
    }
    return null;
  }
}
