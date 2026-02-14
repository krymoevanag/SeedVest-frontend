import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../cache/cache_service.dart';
import 'connectivity_service.dart';

class ApiService {
  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  ApiService() {
    // Use environment-based URL configuration
    dio.options.baseUrl = AppConfig.apiUrl;
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
        // JWT Auto-Refresh on 401 Unauthorized
        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              // Attempt to refresh the token
              final response = await dio.post(
                '/token/refresh/',
                data: {'refresh': refreshToken},
              );
              
              // Store new access token
              await storage.write(
                key: 'access_token',
                value: response.data['access'],
              );
              
              // Retry the original request with new token
              final opts = Options(
                method: e.requestOptions.method,
                headers: {
                  ...e.requestOptions.headers,
                  'Authorization': 'Bearer ${response.data['access']}'
                },
              );
              
              final cloneReq = await dio.request(
                e.requestOptions.path,
                options: opts,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
              );
              
              return handler.resolve(cloneReq);
            } catch (refreshError) {
              // Refresh failed, clear tokens (user needs to login again)
              await storage.deleteAll();
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  // Connectivity Check
  Future<bool> checkConnectivity() async {
    try {
      final response = await dio.get(
        '/health/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  // Auth Methods
  Future<void> requestPasswordReset(String email) async {
    await dio.post('/password-reset/', data: {'email': email});
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/token/', data: {
      'email': email,
      'password': password,
    });
    
    // Store additional user info
    if (response.data['role'] != null) {
      await storage.write(key: 'user_role', value: response.data['role']);
    }
    if (response.data['user_id'] != null) {
      await storage.write(key: 'user_id', value: response.data['user_id'].toString());
    }
    
    
    return response.data;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await dio.post('/accounts/logout/', data: {'refresh': refreshToken});
      }
    } catch (e) {
      // Ignore errors during logout (e.g. if token is already invalid)
    } finally {
      await storage.deleteAll();
      await _cacheService.clearCache();
    }
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    return await dio.post('/accounts/register/', data: userData);
  }

  Future<Response> updateProfile(Map<String, dynamic> userData) async {
    return await dio.patch('/accounts/users/me/', data: userData);
  }

  // Payment Methods
  Future<Response> initiateMpesaPayment(double amount, String phoneNumber) async {
    return await dio.post('/payments/mpesa/pay/', data: {
      'amount': amount,
      'phone_number': phoneNumber,
    });
  }

  // Finance Methods with Offline Support
  Future<Response> getContributions() async {
    const cacheKey = 'contributions';
    try {
      final response = await dio.get('/finance/contributions/');
      // Cache successful response
      if (AppConfig.isOfflineModeEnabled) {
        await _cacheService.cacheData(cacheKey, response.data);
      }
      return response;
    } catch (e) {
      // If offline, return cached data
      if (AppConfig.isOfflineModeEnabled && !await _connectivityService.isConnected) {
        final cached = _cacheService.getCachedData(cacheKey, maxAge: const Duration(hours: 1));
        if (cached != null) {
          return Response(
            requestOptions: RequestOptions(path: '/finance/contributions/'),
            data: cached,
            statusCode: 200,
          );
        }
      }
      rethrow;
    }
  }

  Future<Response> getPenalties() async {
    const cacheKey = 'penalties';
    try {
      final response = await dio.get('/finance/penalties/');
      // Cache successful response
      if (AppConfig.isOfflineModeEnabled) {
        await _cacheService.cacheData(cacheKey, response.data);
      }
      return response;
    } catch (e) {
      // If offline, return cached data
      if (AppConfig.isOfflineModeEnabled && !await _connectivityService.isConnected) {
        final cached = _cacheService.getCachedData(cacheKey, maxAge: const Duration(hours: 1));
        if (cached != null) {
          return Response(
            requestOptions: RequestOptions(path: '/finance/penalties/'),
            data: cached,
            statusCode: 200,
          );
        }
      }
      rethrow;
    }
  }

  // Governance & Admin Methods
  Future<Response> getAdminStats() async {
    return await dio.get('/accounts/admin-stats/');
  }

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
