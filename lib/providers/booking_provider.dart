import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({BookingService? bookingService})
    : _bookingService = bookingService ?? BookingService();

  final BookingService _bookingService;

  List<Booking> _bookings = [];
  Booking? _selectedBooking;

  bool _isLoading = false;
  String? _errorMessage;

  List<Booking> get bookings => List.unmodifiable(_bookings);

  Booking? get selectedBooking => _selectedBooking;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadBookings() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _bookings = await _bookingService.getBookings();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadBooking(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedBooking = await _bookingService.getBooking(id);
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBooking({
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
    _setLoading(true);
    _errorMessage = null;

    try {
      final booking = await _bookingService.createBooking(
        vehicleId: vehicleId,
        tanggal: tanggal,
        waktu: waktu,
        keluhan: keluhan,
        diagnosisCustomer: diagnosisCustomer,
        jenisLayanan: jenisLayanan,
        pickupRequested: pickupRequested,
        alamatPickup: alamatPickup,
        estimatedDistanceKm: estimatedDistanceKm,
        catatan: catatan,
      );

      _bookings = [booking, ..._bookings];

      _selectedBooking = booking;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmBooking(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final booking = await _bookingService.confirmBooking(id);

      _bookings = _bookings
          .map((item) => item.id == id ? booking : item)
          .toList();

      if (_selectedBooking?.id == id) {
        _selectedBooking = booking;
      }

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> cancelBooking(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final booking = await _bookingService.cancelBooking(id);

      _bookings = _bookings
          .map((item) => item.id == id ? booking : item)
          .toList();

      if (_selectedBooking?.id == id) {
        _selectedBooking = booking;
      }

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectBooking(Booking? booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearBookings() {
    _bookings = [];
    _selectedBooking = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return ApiException.extractMessage(error);
  }
}
