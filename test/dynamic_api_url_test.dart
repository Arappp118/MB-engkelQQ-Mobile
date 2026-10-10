import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mb_engkelqq_mobile/core/config/api_config.dart';
import 'package:mb_engkelqq_mobile/core/constants/api_constants.dart';
import 'package:mb_engkelqq_mobile/core/network/api_client.dart';
import 'package:mb_engkelqq_mobile/core/storage/secure_storage.dart';
import 'package:mb_engkelqq_mobile/features/settings/api_settings_page.dart';

class FakeSecureStorage extends SecureStorage {
  FakeSecureStorage() : super();

  final Map<String, String> _data = {};

  @override
  Future<void> saveToken(String token) async {
    _data[SecureStorage.tokenKey] = token;
  }

  @override
  Future<String?> getToken() async {
    return _data[SecureStorage.tokenKey];
  }

  @override
  Future<void> saveUser(String userJson) async {
    _data[SecureStorage.userKey] = userJson;
  }

  @override
  Future<String?> getUser() async {
    return _data[SecureStorage.userKey];
  }

  @override
  Future<void> saveBaseUrl(String url) async {
    _data[SecureStorage.baseUrlKey] = url;
  }

  @override
  Future<String?> getBaseUrl() async {
    return _data[SecureStorage.baseUrlKey];
  }

  @override
  Future<void> clearBaseUrl() async {
    _data.remove(SecureStorage.baseUrlKey);
  }

  @override
  Future<void> clearAuth() async {
    _data.remove(SecureStorage.tokenKey);
    _data.remove(SecureStorage.userKey);
  }
}

class MockHttpClient extends http.BaseClient {
  MockHttpClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _handler(request);
}

void main() {
  group('Dynamic API Base URL - Normalization & Validation', () {
    test('provides correct default emulator base URL', () {
      expect(ApiConfig.defaultBaseUrl, 'http://10.0.2.2:8000/api/v1');
      expect(ApiConstants.defaultBaseUrl, 'http://10.0.2.2:8000/api/v1');
    });

    test('rejects empty and whitespace-only URLs', () {
      expect(() => ApiConfig.normalizeUrl(''), throwsA(isA<FormatException>()));
      expect(
        () => ApiConfig.normalizeUrl('   '),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects malformed URLs and non-HTTP/HTTPS schemes', () {
      expect(
        () => ApiConfig.normalizeUrl('not-a-valid-url'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ApiConfig.normalizeUrl('ftp://192.168.1.19:8000/api/v1'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ApiConfig.normalizeUrl('ws://192.168.1.19:8000/api/v1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('strips trailing slashes consistently', () {
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000/api/v1/'),
        'http://192.168.1.19:8000/api/v1',
      );
      expect(
        ApiConfig.normalizeUrl('https://example.com/api/v1///'),
        'https://example.com/api/v1',
      );
    });

    test('appends /api/v1 if root or missing', () {
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000'),
        'http://192.168.1.19:8000/api/v1',
      );
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000/'),
        'http://192.168.1.19:8000/api/v1',
      );
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000/api'),
        'http://192.168.1.19:8000/api/v1',
      );
      expect(
        ApiConfig.normalizeUrl('https://cloud.motocare.id'),
        'https://cloud.motocare.id/api/v1',
      );
    });

    test('prevents duplicate /api/v1 in path', () {
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000/api/v1/api/v1'),
        'http://192.168.1.19:8000/api/v1',
      );
      expect(
        ApiConfig.normalizeUrl('http://192.168.1.19:8000/api/v1'),
        'http://192.168.1.19:8000/api/v1',
      );
    });
  });

  group('Dynamic API Base URL - Persistence & Storage Isolation', () {
    late FakeSecureStorage storage;

    setUp(() {
      storage = FakeSecureStorage();
    });

    test('initializes with default URL when storage is empty', () async {
      final config = ApiConfig(storage: storage);
      await config.initialize();

      expect(config.baseUrl, ApiConfig.defaultBaseUrl);
      expect(config.isDefault, isTrue);
    });

    test('loads saved URL from storage on initialization', () async {
      await storage.saveBaseUrl('http://192.168.1.50:8000/api/v1');

      final config = ApiConfig(storage: storage);
      await config.initialize();

      expect(config.baseUrl, 'http://192.168.1.50:8000/api/v1');
      expect(config.isDefault, isFalse);
    });

    test('updates and persists URL', () async {
      final config = ApiConfig(storage: storage);
      await config.initialize();

      await config.setBaseUrl('http://192.168.1.99:8000');
      expect(config.baseUrl, 'http://192.168.1.99:8000/api/v1');
      expect(await storage.getBaseUrl(), 'http://192.168.1.99:8000/api/v1');
    });

    test('resetToDefault reverts URL and clears storage key', () async {
      final config = ApiConfig(storage: storage);
      await config.setBaseUrl('http://192.168.1.99:8000');

      await config.resetToDefault();
      expect(config.baseUrl, ApiConfig.defaultBaseUrl);
      expect(await storage.getBaseUrl(), isNull);
    });

    test(
      'updating base URL does NOT wipe or modify auth token or user',
      () async {
        await storage.saveToken('secure-user-token-xyz');
        await storage.saveUser('{"id":1,"name":"Test User"}');

        final config = ApiConfig(storage: storage);
        await config.setBaseUrl('http://192.168.1.200:8000/api/v1');

        expect(await storage.getToken(), 'secure-user-token-xyz');
        expect(await storage.getUser(), '{"id":1,"name":"Test User"}');

        await config.resetToDefault();
        expect(await storage.getToken(), 'secure-user-token-xyz');
        expect(await storage.getUser(), '{"id":1,"name":"Test User"}');
      },
    );

    test('clearAuth (logout) does NOT remove api_base_url', () async {
      await storage.saveBaseUrl('http://192.168.1.200:8000/api/v1');
      await storage.saveToken('secure-user-token-xyz');

      await storage.clearAuth();

      expect(await storage.getToken(), isNull);
      expect(await storage.getBaseUrl(), 'http://192.168.1.200:8000/api/v1');
    });
  });

  group('ApiClient Dynamic Base URL Integration', () {
    test('ApiClient dynamically uses latest base URL from ApiConfig', () async {
      final storage = FakeSecureStorage();
      final config = ApiConfig(storage: storage);
      await config.initialize();

      Uri? capturedUri;
      final mockClient = MockHttpClient((request) async {
        capturedUri = request.url;
        return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'success': true, 'data': {}}))),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(
        storage: storage,
        config: config,
        httpClient: mockClient,
      );

      // First request with default emulator URL
      await apiClient.get('/vehicles');
      expect(capturedUri.toString(), 'http://10.0.2.2:8000/api/v1/vehicles');

      // Update base URL to LAN IP
      await config.setBaseUrl('http://192.168.1.25:8000/api/v1');

      // Next request immediately uses new base URL
      await apiClient.get('/vehicles');
      expect(
        capturedUri.toString(),
        'http://192.168.1.25:8000/api/v1/vehicles',
      );

      // Update to hosting domain
      await config.setBaseUrl('https://api.motocare.com/api/v1');

      await apiClient.post(
        '/auth/login',
        body: {'email': 'a', 'password': 'b'},
      );
      expect(
        capturedUri.toString(),
        'https://api.motocare.com/api/v1/auth/login',
      );
    });
  });

  group('Connection Test', () {
    test(
      'returns success with server version and latency when backend is healthy',
      () async {
        final mockClient = MockHttpClient((request) async {
          expect(request.url.path, '/api/v1/health');
          return http.StreamedResponse(
            Stream.value(
              utf8.encode(
                jsonEncode({
                  'success': true,
                  'message': 'MotoCare API berjalan',
                  'data': {'version': 'v1'},
                }),
              ),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final config = ApiConfig(httpClient: mockClient);
        final result = await config.testConnection(
          'http://192.168.1.19:8000/api/v1',
        );

        expect(result.isSuccess, isTrue);
        expect(result.version, 'v1');
        expect(result.message, contains('MotoCare API berjalan'));
        expect(result.statusCode, 200);
        expect(result.latency, isNotNull);
      },
    );

    test('differentiates 404 endpoint not found', () async {
      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('Not Found')),
          404,
        );
      });

      final config = ApiConfig(httpClient: mockClient);
      final result = await config.testConnection(
        'http://192.168.1.19:8000/api/v1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 404);
      expect(result.message, contains('404'));
    });

    test('differentiates 500 internal server error', () async {
      final mockClient = MockHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('Internal Server Error')),
          500,
        );
      });

      final config = ApiConfig(httpClient: mockClient);
      final result = await config.testConnection(
        'http://192.168.1.19:8000/api/v1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.statusCode, 500);
      expect(result.message, contains('500'));
    });

    test(
      'differentiates network connection failure (SocketException)',
      () async {
        final mockClient = MockHttpClient((request) async {
          throw const SocketException('Failed host lookup');
        });

        final config = ApiConfig(httpClient: mockClient);
        final result = await config.testConnection(
          'http://192.168.1.19:8000/api/v1',
        );

        expect(result.isSuccess, isFalse);
        expect(result.message, contains('Tidak dapat terhubung'));
        expect(result.message, contains('php artisan serve'));
      },
    );

    test('differentiates timeout error (TimeoutException)', () async {
      final mockClient = MockHttpClient((request) async {
        throw TimeoutException('Request timed out');
      });

      final config = ApiConfig(httpClient: mockClient);
      final result = await config.testConnection(
        'http://192.168.1.19:8000/api/v1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, contains('timeout'));
    });
  });

  group('ApiSettingsPage Widget Tests', () {
    testWidgets(
      'renders active URL card, input field, presets, and action buttons',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: ApiSettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Pengaturan Server API'), findsOneWidget);
        expect(find.text('URL Aktif Saat Ini'), findsOneWidget);
        expect(find.text('Ubah Alamat Server'), findsOneWidget);
        expect(find.text('Tes Koneksi'), findsOneWidget);
        expect(find.text('Simpan URL'), findsOneWidget);
        expect(
          find.text('Panduan Testing di HP Android Fisik'),
          findsOneWidget,
        );

        // Preset chips
        expect(find.text('Emulator (10.0.2.2)'), findsOneWidget);
        expect(find.text('Contoh LAN HP'), findsOneWidget);
        expect(find.text('Localhost (127.0.0.1)'), findsOneWidget);
        expect(find.text('Domain HTTPS'), findsOneWidget);
      },
    );

    testWidgets('tapping preset chip updates text field', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ApiSettingsPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contoh LAN HP'));
      await tester.pumpAndSettle();

      final textField = tester.widget<TextFormField>(
        find.byType(TextFormField),
      );
      expect(textField.controller?.text, 'http://192.168.1.19:8000/api/v1');
    });
  });
}
