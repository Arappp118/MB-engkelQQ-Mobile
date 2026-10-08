class Booking {
  const Booking({
    required this.id,
    required this.vehicleId,
    this.nomorBooking,
    this.customerId,
    this.tanggal,
    this.waktu,
    this.keluhan,
    this.diagnosisCustomer,
    this.jenisLayanan,
    this.pickupRequested,
    this.alamatPickup,
    this.estimatedDistanceKm,
    this.status,
    this.catatan,
    this.cancellationReason,
  });

  final int id;
  final int vehicleId;
  final String? nomorBooking;
  final int? customerId;
  final String? tanggal;
  final String? waktu;
  final String? keluhan;
  final String? diagnosisCustomer;
  final String? jenisLayanan;
  final bool? pickupRequested;
  final String? alamatPickup;
  final double? estimatedDistanceKm;
  final String? status;
  final String? catatan;
  final String? cancellationReason;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: _toInt(json['id']) ?? 0,
      vehicleId: _toInt(json['vehicle_id']) ?? 0,
      nomorBooking: json['nomor_booking']?.toString(),
      customerId: _toInt(json['customer_id']),
      tanggal: json['tanggal']?.toString(),
      waktu: json['waktu']?.toString(),
      keluhan: json['keluhan']?.toString(),
      diagnosisCustomer: json['diagnosis_customer']?.toString(),
      jenisLayanan: json['jenis_layanan']?.toString(),
      pickupRequested: _toBool(json['pickup_requested']),
      alamatPickup: json['alamat_pickup']?.toString(),
      estimatedDistanceKm: _toDouble(json['estimated_distance_km']),
      status: json['status']?.toString(),
      catatan: json['catatan']?.toString(),
      cancellationReason: json['cancellation_reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'nomor_booking': nomorBooking,
      'customer_id': customerId,
      'tanggal': tanggal,
      'waktu': waktu,
      'keluhan': keluhan,
      'diagnosis_customer': diagnosisCustomer,
      'jenis_layanan': jenisLayanan,
      'pickup_requested': pickupRequested,
      'alamat_pickup': alamatPickup,
      'estimated_distance_km': estimatedDistanceKm,
      'status': status,
      'catatan': catatan,
      'cancellation_reason': cancellationReason,
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

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') {
        return true;
      }

      if (value == '0' || value.toLowerCase() == 'false') {
        return false;
      }
    }

    return null;
  }
}
