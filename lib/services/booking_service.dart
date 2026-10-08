import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/booking.dart';

class BookingService {
  BookingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Booking>> getBookings() async {
    final response = await _apiClient.get(ApiConstants.bookings);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response booking tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Booking.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Booking> getBooking(int id) async {
    final response = await _apiClient.get('${ApiConstants.bookings}/$id');

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail booking tidak memiliki format data yang valid.',
      );
    }

    return Booking.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Booking> createBooking({
    required int vehicleId,
    required String tanggal,
    required String waktu,
    required String keluhan,
    String? diagnosisCustomer,
    required String jenisLayanan,
    required bool pickupRequested,
    String? alamatPickup,
    double? estimatedDistanceKm,
    String? catatan,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.bookings,
      body: {
        'vehicle_id': vehicleId,
        'tanggal': tanggal,
        'waktu': waktu,
        'keluhan': keluhan,
        'diagnosis_customer': diagnosisCustomer,
        'jenis_layanan': jenisLayanan,
        'pickup_requested': pickupRequested,
        'alamat_pickup': alamatPickup,
        'estimated_distance_km': estimatedDistanceKm,
        'catatan': catatan,
      },
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response booking baru tidak memiliki format data yang valid.',
      );
    }

    return Booking.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Booking> confirmBooking(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.bookings}/$id/confirm',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response konfirmasi booking tidak memiliki format data yang valid.',
      );
    }

    return Booking.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Booking> cancelBooking(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.bookings}/$id/cancel',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response pembatalan booking tidak memiliki format data yang valid.',
      );
    }

    return Booking.fromJson(Map<String, dynamic>.from(data));
  }
}
