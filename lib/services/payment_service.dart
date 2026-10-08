import 'dart:io';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/payment.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Payment> getPayment(int paymentId) async {
    final response = await _apiClient.get(
      '${ApiConstants.payments}/$paymentId',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response payment tidak memiliki format data yang valid.',
      );
    }

    return Payment.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Payment> createPayment({
    required int serviceOrderId,
    required String method,
    String? proofPath,
  }) async {
    final normalizedMethod = method.toLowerCase().trim();

    const allowedMethods = {'cash', 'transfer', 'qris'};

    if (!allowedMethods.contains(normalizedMethod)) {
      throw ArgumentError('Metode pembayaran tidak valid.');
    }

    if (normalizedMethod == 'cash') {
      if (proofPath != null && proofPath.isNotEmpty) {
        throw ArgumentError(
          'Pembayaran cash tidak memerlukan bukti pembayaran.',
        );
      }

      final response = await _apiClient.post(
        '${ApiConstants.serviceOrders}/$serviceOrderId/payments',
        body: {'payment_method': normalizedMethod},
      );

      return _parsePayment(response);
    }

    if (proofPath == null || proofPath.isEmpty) {
      throw ArgumentError('Bukti pembayaran wajib untuk transfer/QRIS.');
    }

    await _validateProofFile(proofPath);

    return _createPaymentWithProof(
      serviceOrderId: serviceOrderId,
      method: normalizedMethod,
      proofPath: proofPath,
    );
  }

  Future<Payment> _createPaymentWithProof({
    required int serviceOrderId,
    required String method,
    required String proofPath,
  }) async {
    final response = await _apiClient.postMultipart(
      '${ApiConstants.serviceOrders}/$serviceOrderId/payments',
      fields: {'payment_method': method},
      filePath: proofPath,
      fileField: 'proof',
    );

    return _parsePayment(response);
  }

  Future<void> _validateProofFile(String proofPath) async {
    final file = File(proofPath);

    if (!await file.exists()) {
      throw ArgumentError('File bukti pembayaran tidak ditemukan.');
    }

    final fileSize = await file.length();

    const maxBytes = 2 * 1024 * 1024;

    if (fileSize > maxBytes) {
      throw ArgumentError('Ukuran bukti pembayaran maksimal 2 MB.');
    }

    final extension = proofPath.split('.').last.toLowerCase();

    const allowedExtensions = {'jpg', 'jpeg', 'png', 'pdf'};

    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError(
        'Format bukti pembayaran harus JPG, JPEG, PNG, atau PDF.',
      );
    }
  }

  Future<Payment> verifyPayment(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.payments}/$id/verify',
    );

    return _parsePayment(response);
  }

  Future<Payment> rejectPayment(int id, {String? reason}) async {
    final response = await _apiClient.post(
      '${ApiConstants.payments}/$id/reject',
      body: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );

    return _parsePayment(response);
  }

  Payment _parsePayment(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response pembayaran tidak memiliki format data yang valid.',
      );
    }

    return Payment.fromJson(Map<String, dynamic>.from(data));
  }
}
