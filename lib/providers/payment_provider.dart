import 'package:flutter/foundation.dart';

import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;

  Payment? _selectedPayment;

  bool _isLoading = false;
  String? _errorMessage;

  Payment? get selectedPayment => _selectedPayment;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadPayment(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedPayment = await _paymentService.getPayment(id);
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createPayment({
    required int serviceOrderId,
    required String method,
    String? proofPath,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedPayment = await _paymentService.createPayment(
        serviceOrderId: serviceOrderId,
        method: method,
        proofPath: proofPath,
      );

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPayment(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedPayment = await _paymentService.verifyPayment(id);

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectPayment(int id, {String? reason}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedPayment = await _paymentService.rejectPayment(
        id,
        reason: reason,
      );

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectPayment(Payment? payment) {
    _selectedPayment = payment;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearPayment() {
    _selectedPayment = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}
