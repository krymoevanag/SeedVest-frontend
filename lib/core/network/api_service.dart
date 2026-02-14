import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  
  // Use 10.0.2.2 for Android emulator to access localhost
  static const String baseUrl = "http://10.0.2.2:8000/api";

  ApiService() {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // TODO: Implement token refresh logic
        }
        return handler.next(e);
      },
    ));
  }

  // Auth Methods
  Future<Response> login(String username, String password) async {
    return await dio.post('/token/', data: {
      'username': username,
      'password': password,
    });
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    return await dio.post('/accounts/register/', data: userData);
  }

  // Payment Methods
  Future<Response> initiateMpesaPayment(double amount, String phoneNumber) async {
    return await dio.post('/payments/mpesa/pay/', data: {
      'amount': amount,
      'phone_number': phoneNumber,
    });
  }

  // Finance Methods
  Future<Response> getContributions() async {
    return await dio.get('/finance/contributions/');
  }

  Future<Response> getPenalties() async {
    return await dio.get('/finance/penalties/');
  }

  // Governance & Admin Methods
  Future<Response> getPendingUsers() async {
    return await dio.get('/accounts/pending-users/');
  }

  Future<Response> approveUser(int userId) async {
    return await dio.patch('/accounts/users/$userId/', data: {
      'is_approved': true,
    });
  }

  Future<Response> updateUserRole(int userId, String role) async {
    return await dio.patch('/accounts/users/$userId/', data: {
      'role': role,
    });
  }

  Future<Response> getAuditLogs() async {
    return await dio.get('/notifications/notifications/');
  }

  Future<Response> getInvestments() async {
    return await dio.get('/finance/investments/');
  }

  Future<Response> createInvestment(Map<String, dynamic> data) async {
    return await dio.post('/finance/investments/', data: data);
  }

  Future<Response> issuePenalty(Map<String, dynamic> data) async {
    return await dio.post('/finance/penalties/', data: data);
  }
}
