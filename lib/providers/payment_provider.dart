import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  PaymentProvider({PaymentService? paymentService})
    : _paymentService = paymentService ?? PaymentService();

  final PaymentService _paymentService;

  Payment? _selectedPayment;
  final Map<int, Payment> _paymentsByOrderId = {};
  final Map<int, Payment> _paymentsById = {};

  bool _isLoading = false;
  String? _errorMessage;

  Payment? get selectedPayment => _selectedPayment;
  Payment? getPaymentForOrder(int orderId) => _paymentsByOrderId[orderId];
  Payment? getPaymentById(int id) => _paymentsById[id];

  void cachePayment(Payment payment) {
    if (payment.serviceOrderId != null) {
      _paymentsByOrderId[payment.serviceOrderId!] = payment;
    }
    _paymentsById[payment.id] = payment;
  }

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadPayment(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final payment = await _paymentService.getPayment(id);
      _selectedPayment = payment;
      cachePayment(payment);
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
      final payment = await _paymentService.createPayment(
        serviceOrderId: serviceOrderId,
        method: method,
        proofPath: proofPath,
      );
      _selectedPayment = payment;
      cachePayment(payment);

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
      final payment = await _paymentService.verifyPayment(id);
      _selectedPayment = payment;
      cachePayment(payment);

      if (payment.status?.toLowerCase() != 'verified') {
        _errorMessage =
            'Status pembayaran dari server bukan terverifikasi: ${payment.status}';
        return false;
      }

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
      final payment = await _paymentService.rejectPayment(
        id,
        reason: reason,
      );
      _selectedPayment = payment;
      cachePayment(payment);

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
    return ApiException.extractMessage(error);
  }
}
