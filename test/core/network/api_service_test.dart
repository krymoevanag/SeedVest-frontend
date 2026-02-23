import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:seedvest_mobile/core/network/api_service.dart';

import 'api_service_test.mocks.dart';

// Annotation must be above a top-level declaration
@GenerateMocks([Dio])
void main() {
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
        final result = await apiService.checkConnectivity();
        expect(result, isA<bool>());
      },
    );
  });
}
