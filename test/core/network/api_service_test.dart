import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seedvest_mobile/core/cache/cache_service.dart';
import 'package:seedvest_mobile/core/network/api_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await CacheService.init();
  });

  group('ApiService Tests', () {
    late ApiService apiService;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      apiService = ApiService();
      await CacheService().clearCache();
    });

    test(
      'clearSessionAndBiometric preserves offline login data for offline re-entry',
      () async {
        const email = 'member@example.com';
        const password = 'SecretPass123';
        final passwordHash = sha256.convert(utf8.encode(password)).toString();

        await apiService.storage.write(key: 'access_token', value: 'access');
        await apiService.storage.write(key: 'refresh_token', value: 'refresh');
        await apiService.storage.write(key: 'user_role', value: 'MEMBER');
        await apiService.storage.write(key: 'user_id', value: '7');
        await apiService.storage.write(key: 'biometric_enabled', value: 'true');
        await apiService.storage.write(key: 'offline_login_email', value: email);
        await apiService.storage.write(
          key: 'offline_login_password_hash',
          value: passwordHash,
        );
        await apiService.storage.write(
          key: 'offline_login_user_profile',
          value: jsonEncode({
            'id': 7,
            'email': email,
            'full_name': 'Offline Member',
            'role': 'MEMBER',
          }),
        );

        await apiService.clearSessionAndBiometric();

        expect(await apiService.storage.read(key: 'access_token'), isNull);
        expect(await apiService.storage.read(key: 'refresh_token'), isNull);
        expect(await apiService.storage.read(key: 'user_role'), isNull);
        expect(await apiService.storage.read(key: 'user_id'), isNull);
        expect(await apiService.storage.read(key: 'biometric_enabled'), isNull);
        expect(await apiService.storage.read(key: 'offline_login_email'), email);
        expect(
          await apiService.storage.read(key: 'offline_login_password_hash'),
          passwordHash,
        );

        apiService.dio.httpClientAdapter = _FailingHttpClientAdapter();

        final response = await apiService.login(email, password);

        expect(response.statusCode, 200);
        expect(response.data['offline_login'], isTrue);
      },
    );

    test(
      'getProfile falls back to the stored offline profile when offline',
      () async {
        const profile = {
          'id': 12,
          'email': 'cached@example.com',
          'full_name': 'Cached User',
          'role': 'MEMBER',
        };

        await apiService.storage.write(
          key: 'offline_login_user_profile',
          value: jsonEncode(profile),
        );
        apiService.dio.httpClientAdapter = _FailingHttpClientAdapter();

        final response = await apiService.getProfile();

        expect(response.statusCode, 200);
        expect(response.data, profile);
      },
    );
  });
}

class _FailingHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'Simulated connection failure',
    );
  }
}
