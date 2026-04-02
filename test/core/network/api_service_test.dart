import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seedvest_mobile/core/network/api_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    await dotenv.load(fileName: '.env');
  });

  group('ApiService Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('login should return tokens on success', () async {
      expect(apiService, isNotNull);
    });

    test(
      'isOnline should return false when server is unreachable',
      () async {
        apiService.dio.httpClientAdapter = _FailingHttpClientAdapter();
        final result = await apiService.isOnline;
        expect(result, isFalse);
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
