import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  ApiClient({SecureStorage? storage})
    : _storage = storage ?? SecureStorage.instance;

  final SecureStorage _storage;

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
          .replace(queryParameters: queryParameters);

      final response = await http
          .get(uri, headers: await _headers())
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi ke server timeout. Silakan coba beberapa saat lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Gagal berkomunikasi dengan server. Silakan periksa jaringan.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http
          .post(
            uri,
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi ke server timeout. Silakan coba beberapa saat lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Gagal berkomunikasi dengan server. Silakan periksa jaringan.',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http
          .put(
            uri,
            headers: await _headers(),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi ke server timeout. Silakan coba beberapa saat lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Gagal berkomunikasi dengan server. Silakan periksa jaringan.',
      );
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http
          .delete(uri, headers: await _headers())
          .timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi ke server timeout. Silakan coba beberapa saat lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Gagal berkomunikasi dengan server. Silakan periksa jaringan.',
      );
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    String? filePath,
    String fileField = 'proof',
  }) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final token = await _storage.getToken();

      final request = http.MultipartRequest('POST', uri);

      request.headers['Accept'] = 'application/json';

      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);

        if (!await file.exists()) {
          throw const ApiException(
            message: 'File bukti pembayaran tidak ditemukan.',
          );
        }

        request.files.add(
          await http.MultipartFile.fromPath(fileField, filePath),
        );
      }

      final streamedResponse = await request.send().timeout(
        ApiConstants.connectTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'Koneksi ke server timeout. Silakan coba beberapa saat lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'Gagal berkomunikasi dengan server. Silakan periksa jaringan.',
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getToken();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  String _formatValidationErrors(String message, Map<String, dynamic> errors) {
    final details = <String>[];

    for (final entry in errors.entries) {
      final value = entry.value;

      if (value is List) {
        for (final item in value) {
          details.add('${entry.key}: $item');
        }
      } else {
        details.add('${entry.key}: $value');
      }
    }

    if (details.isEmpty) {
      return message;
    }

    return '$message\n\n${details.join('\n')}';
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    dynamic decoded;

    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw ApiException(
          message: 'Server mengembalikan response yang tidak valid.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return <String, dynamic>{'success': true, 'data': decoded};
    }

    String message = 'Terjadi kesalahan pada server.';

    Map<String, dynamic>? errors;

    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) {
        message = decoded['message'] as String;
      }

      if (decoded['errors'] is Map) {
        errors = Map<String, dynamic>.from(decoded['errors'] as Map);
      }
    }

    throw ApiException(
      message: errors == null
          ? message
          : _formatValidationErrors(message, errors),
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
