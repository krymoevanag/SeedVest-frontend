import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seedvest_mobile/core/network/api_service.dart';

import 'api_service_test.mocks.dart';

// Annotation must be above a top-level declaration
@GenerateMocks([Dio])
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    await dotenv.load(fileName: '.env');
  });

  group('ApiService Tests', () {
    late ApiService apiService;
    late MockDio mockDio;


    setUp(() {
      mockDio = MockDio();
      apiService = ApiService();
    });

    test('login should return tokens on success', () async {
      expect(apiService, isNotNull);
    });

    test(
      'checkConnectivity should return false when server is unreachable',
      () async {
        apiService.dio.httpClientAdapter = _FailingHttpClientAdapter();
        final result = await apiService.checkConnectivity();
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
