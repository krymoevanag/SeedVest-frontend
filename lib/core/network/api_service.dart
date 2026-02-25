// lib/core/network/api_service.dart
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
    dio.options.baseUrl = AppConfig.apiUrl;
    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await storage.read(key: 'access_token');

        if (token != null &&
            !options.path.contains('password-reset') &&
            !options.path.contains('token/')) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Don't attempt refresh for login or refresh tokens themselves
        if (e.requestOptions.path.contains('accounts/login/') ||
            e.requestOptions.path.contains('token/refresh/')) {
          return handler.next(e);
        }

        if (e.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final response = await dio.post('token/refresh/', data: {
                'refresh': refreshToken,
              });

              await storage.write(
                key: 'access_token',
                value: response.data['access'],
              );

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
            } catch (_) {
              await storage.deleteAll();
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  /// Connectivity check
  Future<bool> checkConnectivity() async {
    try {
      final response = await dio.get(
        'health/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ======================
  // Auth Methods
  // ======================

  Future<Response> login(String email, String password) async {
    final response = await dio.post('accounts/login/', data: {
      'email': email,
      'password': password,
    });

    if (response.data['access'] != null) {
      await storage.write(key: 'access_token', value: response.data['access']);
    }
    if (response.data['refresh'] != null) {
      await storage.write(
          key: 'refresh_token', value: response.data['refresh']);
    }
    if (response.data['role'] != null) {
      await storage.write(key: 'user_role', value: response.data['role']);
    }
    if (response.data['user_id'] != null) {
      await storage.write(
          key: 'user_id', value: response.data['user_id'].toString());
    }

    return response;
  }

  Future<Response> getNotifications() async {
    return await dio.get('notifications/notifications/');
  }

  Future<Response> markNotificationRead(int id) async {
    return await dio.post('notifications/notifications/$id/mark_read/');
  }

  Future<Response> markAllAllRead() async {
    return await dio.post('notifications/notifications/mark_all_read/');
  }

  Future<Response> sendNotification(Map<String, dynamic> data) async {
    return await dio.post('notifications/notifications/', data: data);
  }

  Future<Response> broadcastNotification(Map<String, dynamic> data) async {
    return await dio.post('notifications/notifications/broadcast/', data: data);
  }

  Future<Response> logout() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        await dio.post('accounts/logout/', data: {'refresh': refreshToken});
      }
    } catch (_) {
      // Ignore logout errors
    } finally {
      await storage.deleteAll();
      await _cacheService.clearCache();
    }
    return Response(
      requestOptions: RequestOptions(path: 'accounts/logout/'),
      statusCode: 200,
      data: {'detail': 'Logged out successfully'},
    );
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    return await dio.post('accounts/register/', data: userData);
  }

  Future<Response> updateProfile(Map<String, dynamic> userData) async {
    return await dio.patch('accounts/users/me/', data: userData);
  }

  Future<Response> updateProfilePicture(String filePath) async {
    FormData formData = FormData.fromMap({
      "profile_picture": await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    return await dio.patch(
      'accounts/users/me/',
      data: formData,
    );
  }

  // ======================
  // Password Reset
  // ======================

  Future<Response> requestPasswordReset(String email) async {
    return await dio.post('accounts/password-reset/', data: {'email': email});
  }

  Future<Response> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    return await dio.post('accounts/password-reset-confirm/', data: {
      'uid': uid,
      'token': token,
      'new_password': newPassword,
    });
  }

  // ======================
  // Finance & Payments
  // ======================

  Future<Response> initiateMpesaPayment(
      double amount, String phoneNumber) async {
    return await dio.post('payments/mpesa/pay/', data: {
      'amount': amount,
      'phone_number': phoneNumber,
    });
  }

  Future<Response> getContributions() async {
    const cacheKey = 'contributions';
    try {
      final response = await dio.get('finance/contributions/');
      if (AppConfig.isOfflineModeEnabled) {
        await _cacheService.cacheData(cacheKey, response.data);
      }
      return response;
    } catch (_) {
      if (AppConfig.isOfflineModeEnabled &&
          !await _connectivityService.isConnected) {
        final cached = _cacheService.getCachedData(cacheKey,
            maxAge: const Duration(hours: 1));
        if (cached != null) {
          return Response(
            requestOptions: RequestOptions(path: 'finance/contributions/'),
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
      final response = await dio.get('finance/penalties/');
      if (AppConfig.isOfflineModeEnabled) {
        await _cacheService.cacheData(cacheKey, response.data);
      }
      return response;
    } catch (_) {
      if (AppConfig.isOfflineModeEnabled &&
          !await _connectivityService.isConnected) {
        final cached = _cacheService.getCachedData(cacheKey,
            maxAge: const Duration(hours: 1));
        if (cached != null) {
          return Response(
            requestOptions: RequestOptions(path: 'finance/penalties/'),
            data: cached,
            statusCode: 200,
          );
        }
      }
      rethrow;
    }
  }

  Future<Response> getInvestments() async {
    return await dio.get('finance/investments/');
  }

  Future<Response> createInvestment(Map<String, dynamic> data) async {
    return await dio.post('finance/investments/', data: data);
  }

  Future<Response> issuePenalty(Map<String, dynamic> data) async {
    return await dio.post('finance/penalties/', data: data);
  }

  // ======================
  // Admin / Governance
  // ======================

  Future<Response> getAdminStats() async {
    return await dio.get('accounts/admin-stats/');
  }

  Future<Response> getPendingUsers() async {
    return await dio.get('accounts/pending-users/');
  }

  Future<Response> getUsers({bool approvedOnly = false}) async {
    return await dio.get('accounts/users/', queryParameters: {
      if (approvedOnly) 'approved_only': 'true',
    });
  }

  Future<Response> adminRegisterUser(Map<String, dynamic> userData) async {
    return await dio.post('accounts/users/admin_register/', data: userData);
  }

  Future<Response> approveUser(int userId) async {
    return await dio.post('accounts/users/$userId/approve/');
  }

  Future<Response> rejectUser(int userId, String reason) async {
    return await dio
        .post('accounts/users/$userId/reject/', data: {'reason': reason});
  }

  Future<Response> updateUserRole(int userId, String role) async {
    return await dio
        .post('accounts/users/$userId/set_role/', data: {'role': role});
  }

  Future<Response> deleteUser(int userId) async {
    return await dio.delete('accounts/users/$userId/');
  }

  Future<Response> deleteSelfAccount() async {
    return await dio.delete('accounts/users/delete_account/');
  }

  Future<Response> approveContribution(int id) async {
    return await dio.post('finance/contributions/$id/approve/');
  }

  Future<Response> rejectContribution(int id) async {
    return await dio.post('finance/contributions/$id/reject/');
  }

  Future<Response> getAuditLogs() async {
    return await dio.get('notifications/notifications/');
  }

  Future<Response> adminAddContribution(Map<String, dynamic> data) async {
    return await dio.post('finance/admin-add-contribution/', data: data);
  }

  Future<Response> getGroups() async {
    return await dio.get('groups/groups/');
  }
}
