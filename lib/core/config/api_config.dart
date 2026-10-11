import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ConnectionTestResult {
  final bool isSuccess;
  final String message;
  final int? statusCode;
  final Duration? latency;
  final String? version;

  const ConnectionTestResult({
    required this.isSuccess,
    required this.message,
    this.statusCode,
    this.latency,
    this.version,
  });

  factory ConnectionTestResult.success({
    required String message,
    int statusCode = 200,
    Duration? latency,
    String? version,
  }) {
    return ConnectionTestResult(
      isSuccess: true,
      message: message,
      statusCode: statusCode,
      latency: latency,
      version: version,
    );
  }

  factory ConnectionTestResult.failure({
    required String message,
    int? statusCode,
  }) {
    return ConnectionTestResult(
      isSuccess: false,
      message: message,
      statusCode: statusCode,
    );
  }
}

class ApiConfig extends ChangeNotifier {
  ApiConfig({SecureStorage? storage, this.httpClient})
    : _storage = storage ?? SecureStorage.instance;

  static ApiConfig instance = ApiConfig();

  final SecureStorage _storage;
  final http.Client? httpClient;

  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1';

  String _baseUrl = defaultBaseUrl;
  bool _isInitialized = false;

  String get baseUrl => _baseUrl;
  bool get isInitialized => _isInitialized;
  bool get isDefault => _baseUrl == defaultBaseUrl;

  /// Returns the base URL for web views/browser (strips /api/v1)
  String get webBaseUrl {
    try {
      final uri = Uri.parse(_baseUrl);
      var path = uri.path;
      if (path.endsWith('/api/v1')) {
        path = path.substring(0, path.length - '/api/v1'.length);
      } else if (path.endsWith('/api/v1/')) {
        path = path.substring(0, path.length - '/api/v1/'.length);
      }
      final stripped = uri.replace(path: path.isEmpty ? '/' : path).toString();
      return stripped.replaceAll(RegExp(r'/+$'), '');
    } catch (_) {
      return _baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final savedUrl = await _storage.getBaseUrl();
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _baseUrl = normalizeUrl(savedUrl);
      } else {
        _baseUrl = defaultBaseUrl;
      }
    } catch (_) {
      _baseUrl = defaultBaseUrl;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setBaseUrl(String rawUrl) async {
    final normalized = normalizeUrl(rawUrl);
    await _storage.saveBaseUrl(normalized);
    _baseUrl = normalized;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    await _storage.clearBaseUrl();
    _baseUrl = defaultBaseUrl;
    _isInitialized = true;
    notifyListeners();
  }

  static bool _isLocalDevHost(String host) {
    if (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2') {
      return true;
    }
    final parts = host.split('.');
    if (parts.length == 4 && parts.every((p) => int.tryParse(p) != null)) {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);
      if (first == 192 && second == 168) return true;
      if (first == 10) return true;
      if (first == 172 && second >= 16 && second <= 31) return true;
      if (first == 127) return true;
    }
    return false;
  }

  /// Normalizes a given URL input:
  /// - Trims whitespace
  /// - Auto-prepends `http://` if scheme is omitted for IP/hostname
  /// - Validates scheme is HTTP or HTTPS
  /// - Auto-assigns port 8000 if user omits port on local LAN development IP (e.g. 192.168.x.x)
  /// - Strips trailing slashes
  /// - Guarantees `/api/v1` path without duplication
  static String normalizeUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('URL API tidak boleh kosong.');
    }

    // Auto-prepend http:// if scheme is missing but user entered host/IP
    if (!trimmed.contains('://')) {
      if (trimmed.contains('.') || trimmed.startsWith('localhost')) {
        trimmed = 'http://$trimmed';
      }
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException(
        'Format URL tidak valid. Contoh: http://192.168.1.19:8000/api/v1',
      );
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      throw const FormatException('Skema URL harus HTTP atau HTTPS.');
    }

    // Determine port:
    // If explicit port is provided, preserve it.
    // If NO port is provided on a local/LAN development IP or localhost under HTTP,
    // default to :8000 (standard Laravel artisan serve port) to prevent accidental port 80 connection failure.
    String portPart;
    if (uri.hasPort) {
      portPart = ':${uri.port}';
    } else if (scheme == 'http' && _isLocalDevHost(uri.host)) {
      portPart = ':8000';
    } else {
      portPart = '';
    }

    final origin = '$scheme://${uri.host}$portPart';

    // Normalize path
    String path = uri.path.trim();

    // Remove any trailing slashes
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }

    // If path is empty, append /api/v1
    if (path.isEmpty) {
      return '$origin/api/v1';
    }

    // Prevent duplicate /api/v1 occurrences
    while (path.contains('/api/v1/api/v1')) {
      path = path.replaceAll('/api/v1/api/v1', '/api/v1');
    }

    if (path.endsWith('/api/v1')) {
      return '$origin$path';
    }

    if (path.endsWith('/api')) {
      return '$origin$path/v1';
    }

    return '$origin$path/api/v1';
  }

  /// Tests connectivity by calling the real Laravel health check endpoint (`/health`).
  Future<ConnectionTestResult> testConnection([String? rawUrl]) async {
    final targetUrl = rawUrl != null ? normalizeUrl(rawUrl) : _baseUrl;
    final testUri = Uri.parse('$targetUrl${ApiConstants.health}');
    final client = httpClient ?? http.Client();
    final stopwatch = Stopwatch()..start();

    try {
      final response = await client
          .get(testUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 7));
      stopwatch.stop();

      final latency = stopwatch.elapsed;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final message = decoded['message'] as String? ?? 'Koneksi berhasil';
            final data = decoded['data'] as Map<String, dynamic>?;
            final version = data?['version'] as String?;
            return ConnectionTestResult.success(
              message: version != null ? '$message ($version)' : message,
              statusCode: response.statusCode,
              latency: latency,
              version: version,
            );
          }
        } catch (_) {
          return ConnectionTestResult.failure(
            message:
                'Server merespons (HTTP ${response.statusCode}), namun format respons bukan JSON yang valid.',
            statusCode: response.statusCode,
          );
        }
        return ConnectionTestResult.success(
          message: 'Koneksi berhasil terhubung.',
          statusCode: response.statusCode,
          latency: latency,
        );
      } else if (response.statusCode == 404) {
        return ConnectionTestResult.failure(
          message: 'Server terjangkau namun endpoint /health tidak ditemukan (HTTP 404). Periksa apakah path /api/v1 sudah sesuai.',
          statusCode: 404,
        );
      } else if (response.statusCode >= 500) {
        return ConnectionTestResult.failure(
          message:
              'Server mengalami kesalahan internal (HTTP ${response.statusCode}). Periksa log Laravel backend.',
          statusCode: response.statusCode,
        );
      } else {
        return ConnectionTestResult.failure(
          message: 'Server merespons dengan kode HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      stopwatch.stop();
      final host = testUri.host;
      final port = testUri.hasPort
          ? testUri.port
          : (testUri.scheme == 'https' ? 443 : 80);
      return ConnectionTestResult.failure(
        message:
            'Tidak dapat terhubung ke $host:$port. Pastikan backend Laravel aktif (php artisan serve --host=0.0.0.0 --port=8000) dan HP terhubung ke jaringan WiFi/LAN yang sama.',
      );
    } on TimeoutException {
      stopwatch.stop();
      return ConnectionTestResult.failure(
        message: 'Koneksi ke server timeout (melebihi batas waktu). Periksa IP laptop, port server, atau firewall sistem.',
      );
    } on http.ClientException catch (e) {
      stopwatch.stop();
      return ConnectionTestResult.failure(
        message:
            'Gagal berkomunikasi dengan server: ${e.message}. Periksa koneksi jaringan HP.',
      );
    } on FormatException catch (e) {
      stopwatch.stop();
      return ConnectionTestResult.failure(message: e.message);
    } catch (e) {
      stopwatch.stop();
      return ConnectionTestResult.failure(
        message: 'Terjadi kesalahan saat menguji koneksi: $e',
      );
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }
}
