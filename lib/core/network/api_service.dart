// lib/core/network/api_service.dart
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/config.dart';
import '../cache/cache_service.dart';
import 'connectivity_service.dart';

class ApiService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _offlineLoginEmailKey = 'offline_login_email';
  static const String _offlineLoginPasswordHashKey =
      'offline_login_password_hash';
  static const String _offlineUserProfileKey = 'offline_login_user_profile';

  final Dio dio = Dio();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final CacheService _cacheService = CacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isPublicEndpoint(String path) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return normalizedPath.startsWith('accounts/login/') ||
        normalizedPath.startsWith('accounts/register/') ||
        normalizedPath.startsWith('accounts/password-reset/') ||
        normalizedPath.startsWith('accounts/activate/') ||
        normalizedPath.startsWith('token/') ||
        normalizedPath.startsWith('groups/groups/') ||
        normalizedPath.startsWith('health/');
  }

  bool _isConnectionFailure(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  String _normalizeMpesaPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s-]+'), '').trim();
    if (cleaned.startsWith('+254')) {
      return cleaned.substring(1);
    }
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      return '254${cleaned.substring(1)}';
    }
    return cleaned;
  }

  ApiService() {
    dio.options.baseUrl = AppConfig.apiUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Keep connectivity listener active for background sync of offline writes
    _connectivityService.init();
    _connectivityService.onConnectivityChanged.listen((online) {
      if (online && AppConfig.isOfflineModeEnabled) {
        syncPendingWrites();
      }
    });

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: _accessTokenKey);

        if (!_isPublicEndpoint(options.path)) {
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
          final refreshToken = await storage.read(key: _refreshTokenKey);
          if (refreshToken != null) {
            try {
              final response = await dio.post('token/refresh/', data: {
                'refresh': refreshToken,
              });

              await storage.write(
                key: _accessTokenKey,
                value: response.data['access'],
              );

              if (response.data['refresh'] != null) {
                await storage.write(
                  key: _refreshTokenKey,
                  value: response.data['refresh'],
                );
              }

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
              await _clearSessionStorage(clearBiometric: true);
              return handler.next(e);
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  /// Connectivity check
  Future<bool> get isOnline async => await _connectivityService.isConnected;

  /// Hash a password for local offline credential check
  Future<String> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> _storeOfflineProfile(Map<String, dynamic> profile) async {
    await storage.write(
      key: _offlineUserProfileKey,
      value: jsonEncode(profile),
    );
  }

  Future<Map<String, dynamic>?> _getStoredOfflineProfile() async {
    final rawProfile = await storage.read(key: _offlineUserProfileKey);
    if (rawProfile == null || rawProfile.isEmpty) return null;

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Ignore malformed local profile payloads and fall back to network/cache.
    }

    return null;
  }

  Future<void> _clearSessionStorage({bool clearBiometric = false}) async {
    await storage.delete(key: _accessTokenKey);
    await storage.delete(key: _refreshTokenKey);
    await storage.delete(key: _userRoleKey);
    await storage.delete(key: _userIdKey);

    if (clearBiometric) {
      await storage.delete(key: _biometricEnabledKey);
    }
  }

  /// Persist offline-safe credentials
  Future<void> _storeOfflineCredentials(String email, String password) async {
    final hashed = await _hashPassword(password);
    await storage.write(
      key: _offlineLoginEmailKey,
      value: email.trim().toLowerCase(),
    );
    await storage.write(key: _offlineLoginPasswordHashKey, value: hashed);
  }

  /// Validate offline login credentials
  Future<bool> _validateOfflineCredentials(
      String email, String password) async {
    final storedEmail = await storage.read(key: _offlineLoginEmailKey);
    final storedHash =
        await storage.read(key: _offlineLoginPasswordHashKey);
    if (storedEmail == null || storedHash == null) return false;
    if (storedEmail.toLowerCase() != email.trim().toLowerCase()) return false;

    final attemptHash = await _hashPassword(password);
    return attemptHash == storedHash;
  }

  /// Helper to ensure network is available for write operations
  Future<void> _ensureOnline() async {
    if (!await isOnline) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Network connection required for this action.',
        type: DioExceptionType.connectionError,
      );
    }
  }

  /// Queue offline-compatible write operations in Hive
  Future<void> _queueOfflineRequest({
    required String method,
    required String path,
    Map<String, dynamic>? data,
  }) async {
    final request = {
      'method': method,
      'path': path,
      'data': data ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _cacheService.addPendingWrite(request);
  }

  /// Execute a write request with offline queuing fallback
  Future<Response> _executeWithOfflineQueue(
    String method,
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _ensureOnline();
      late Response response;

      if (method == 'POST') {
        response = await dio.post(path, data: data);
      } else if (method == 'PATCH') {
        response = await dio.patch(path, data: data);
      } else if (method == 'PUT') {
        response = await dio.put(path, data: data);
      } else if (method == 'DELETE') {
        response = await dio.delete(path, data: data);
      } else {
        throw ArgumentError('Unsupported HTTP method: $method');
      }

      if (AppConfig.isOfflineModeEnabled) {
        await syncPendingWrites();
      }

      return response;
    } on DioException catch (e) {
      // Use offline queue when internet is unavailable
      if (AppConfig.isOfflineModeEnabled && _isConnectionFailure(e)) {
        await _queueOfflineRequest(method: method, path: path, data: data);
        return Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 202,
          data: {
            'detail': 'Operation queued for offline sync',
            'queued_request': {'method': method, 'path': path, 'data': data},
          },
        );
      }

      rethrow;
    }
  }

  /// Process pending offline write requests when connectivity is restored.
  Future<void> syncPendingWrites() async {
    if (!AppConfig.isOfflineModeEnabled || !await isOnline) return;

    final pending = _cacheService.getPendingWrites();
    if (pending.isEmpty) return;

    final remainingQueue = <Map<String, dynamic>>[];

    for (final request in pending) {
      final method = request['method'] as String?;
      final path = request['path'] as String?;
      final data = request['data'] as Map<String, dynamic>?;

      if (method == null || path == null) continue;

      try {
        await _executeWithOfflineQueue(method, path, data: data);
      } catch (_) {
        // Keep this request and don't delete yet if failed.
        remainingQueue.add(request);
      }
    }

    if (remainingQueue.isEmpty) {
      await _cacheService.clearPendingWrites();
    } else {
      await _cacheService.clearPendingWrites();
      for (final item in remainingQueue) {
        await _cacheService.addPendingWrite(item);
      }
    }
  }

  /// Helper to fetch data with local caching fallback
  Future<Response> _getWithCache(
    String path, {
    String? customCacheKey,
    Duration? maxAge,
    Map<String, dynamic>? queryParameters,
  }) async {
    final cacheKey = customCacheKey ?? path;
    final online = await isOnline;

    if (online) {
      try {
        final response = await dio.get(path, queryParameters: queryParameters);
        if (AppConfig.isOfflineModeEnabled) {
          await _cacheService.cacheData(cacheKey, response.data);
        }
        return response;
      } catch (e) {
        // Fallback to cache on network failure even if online check passed
        if (AppConfig.isOfflineModeEnabled) {
          final cached = _cacheService.getCachedData(cacheKey, maxAge: maxAge);
          if (cached != null) {
            return Response(
              data: cached,
              statusCode: 200,
              requestOptions: RequestOptions(path: path),
            );
          }
        }
        rethrow;
      }
    } else {
      if (AppConfig.isOfflineModeEnabled) {
        final cached = _cacheService.getCachedData(cacheKey, maxAge: maxAge);
        if (cached != null) {
          return Response(
            data: cached,
            statusCode: 200,
            requestOptions: RequestOptions(path: path),
          );
        }
      }
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: 'No internet connection. Please try again when online.',
        type: DioExceptionType.connectionError,
      );
    }
  }

  // ======================
  // Auth Methods
  // ======================

  Future<Response> login(String email, String password) async {
    try {
      final response = await dio.post('accounts/login/', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        if (response.data['access'] != null) {
          await storage.write(key: _accessTokenKey, value: response.data['access']);
        }
        if (response.data['refresh'] != null) {
          await storage.write(
              key: _refreshTokenKey, value: response.data['refresh']);
        }
        if (response.data['role'] != null) {
          await storage.write(key: _userRoleKey, value: response.data['role']);
        }
        if (response.data['user_id'] != null) {
          await storage.write(
              key: _userIdKey, value: response.data['user_id'].toString());
        }

        // Save offline credential for fallback login
        if (AppConfig.isOfflineModeEnabled) {
          await _storeOfflineCredentials(email, password);
        }
      }

      return response;
    } on DioException catch (e) {
      // Offline login fallback when app is in offline mode and there is no network
      if (AppConfig.isOfflineModeEnabled && _isConnectionFailure(e)) {
        final verified = await _validateOfflineCredentials(email, password);
        if (verified) {
          // Keep existing tokens if present, but permit use of cached offline data
          return Response(
            requestOptions: RequestOptions(path: 'accounts/login/'),
            statusCode: 200,
            data: {
              'detail': 'Offline login succeeded',
              'offline_login': true,
            },
          );
        } else {
          // Offline credentials not found or invalid
          final deviceOnline = await isOnline;
          throw DioException(
            requestOptions: RequestOptions(path: 'accounts/login/'),
            error:
                deviceOnline
                    ? 'You are connected to the internet, but the SeedVest '
                        'server is not responding right now. We also could '
                        'not verify a saved offline login for this account on '
                        'this device. Please try again shortly.'
                    : 'Unable to login offline. Please check your credentials '
                        'and try again when online.',
            type: DioExceptionType.unknown,
          );
        }
      }

      // Handle network errors when offline mode is disabled
      if (!AppConfig.isOfflineModeEnabled && _isConnectionFailure(e)) {
        final deviceOnline = await isOnline;
        throw DioException(
          requestOptions: RequestOptions(path: 'accounts/login/'),
          error:
              deviceOnline
                  ? 'You are connected to the internet, but the SeedVest '
                      'server is not responding right now. Please try again '
                      'in a few minutes.'
                  : 'No internet connection available. Please check your '
                      'connection and try again.',
          type: DioExceptionType.connectionError,
        );
      }

      // Re-throw other DioExceptions (like 401 unauthorized, etc.)
      rethrow;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final value = await storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      await storage.write(key: _biometricEnabledKey, value: 'true');
    } else {
      await storage.delete(key: _biometricEnabledKey);
    }
  }

  Future<bool> hasRefreshToken() async {
    final refreshToken = await storage.read(key: _refreshTokenKey);
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  Future<bool> refreshAccessToken() async {
    final refreshToken = await storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await dio.post('token/refresh/', data: {
        'refresh': refreshToken,
      });

      if (response.statusCode == 200 && response.data['access'] != null) {
        await storage.write(key: _accessTokenKey, value: response.data['access']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response> clearSessionAndBiometric() async {
    await _clearSessionStorage(clearBiometric: true);
    await _cacheService.clearCache();
    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
    );
  }

  Future<Response> getProfile() async {
    try {
      final response = await _getWithCache('accounts/users/me/',
          customCacheKey: 'user_profile');
      if (response.statusCode == 200 && response.data is Map) {
        await _storeOfflineProfile(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
      return response;
    } on DioException catch (e) {
      if (AppConfig.isOfflineModeEnabled && _isConnectionFailure(e)) {
        final storedProfile = await _getStoredOfflineProfile();
        if (storedProfile != null) {
          return Response(
            data: storedProfile,
            statusCode: 200,
            requestOptions: RequestOptions(path: 'accounts/users/me/'),
          );
        }
      }
      rethrow;
    }
  }

  Future<Response> getNotifications() async {
    return await _getWithCache('notifications/');
  }

  Future<Response> getNotificationPreferences() async {
    return await _getWithCache('notifications/preferences/');
  }

  Future<Response> updateNotificationPreferences(
      Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue(
      'PATCH',
      'notifications/preferences/',
      data: data,
    );
  }

  Future<Response> markNotificationRead(int id) async {
    return await _executeWithOfflineQueue(
        'POST', 'notifications/$id/mark_read/');
  }

  Future<Response> markAllAllRead() async {
    return await _executeWithOfflineQueue(
        'POST', 'notifications/mark_all_read/');
  }

  Future<Response> sendNotification(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'notifications/', data: data);
  }

  Future<Response> broadcastNotification(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'notifications/broadcast/',
        data: data);
  }

  Future<Response> logout() async {
    try {
      await _ensureOnline();
      final refreshToken = await storage.read(key: _refreshTokenKey);
      if (refreshToken != null) {
        await dio.post('accounts/logout/', data: {'refresh': refreshToken});
      }
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _clearSessionStorage(clearBiometric: true);
      await _cacheService.clearCache();
    }
    return Response(
      requestOptions: RequestOptions(path: 'accounts/logout/'),
      statusCode: 200,
      data: {'detail': 'Logged out successfully'},
    );
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    return await _executeWithOfflineQueue('POST', 'accounts/register/',
        data: userData);
  }

  Future<Response> updateProfile(Map<String, dynamic> userData) async {
    return await _executeWithOfflineQueue('PATCH', 'accounts/users/me/',
        data: userData);
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _executeWithOfflineQueue(
        'POST', 'accounts/users/change-password/',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        });
  }

  Future<Response> updateProfilePicture(String filePath) async {
    FormData formData = FormData.fromMap({
      "profile_picture": await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    await _ensureOnline();
    return await dio.patch(
      'accounts/users/me/',
      data: formData,
    );
  }

  // ======================
  // Password Reset
  // ======================

  Future<Response> requestPasswordReset(String email) async {
    return await _executeWithOfflineQueue('POST', 'accounts/password-reset/',
        data: {'email': email});
  }

  Future<Response> confirmPasswordReset({
    required String uid,
    required String token,
    required String newPassword,
  }) async {
    await _ensureOnline();
    return await dio.post('accounts/password-reset-confirm/', data: {
      'uid': uid,
      'token': token,
      'new_password': newPassword,
    });
  }

  // ======================
  // Finance & Payments
  // ======================

  Future<Response> initiateMpesaPayment(double amount, String phoneNumber,
      {int? groupId}) async {
    await _ensureOnline();
    final normalizedPhone = _normalizeMpesaPhone(phoneNumber);
    return await dio.post('payments/mpesa/pay/', data: {
      'amount': amount,
      'phone': normalizedPhone,
      'phone_number': normalizedPhone,
      if (groupId != null) 'group_id': groupId,
    });
  }

  Future<Response> getMpesaPaymentStatus(String checkoutRequestId) async {
    return await dio.get('payments/mpesa/status/$checkoutRequestId/');
  }

  Future<Response> getContributions({
    int? userId,
    int? groupId,
    int? cycleId,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? ordering,
  }) async {
    final queryParameters = <String, dynamic>{
      if (userId != null) 'user_id': userId,
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (status != null && status.isNotEmpty) 'status': status,
      if (dateFrom != null) 'date_from': dateFrom.toIso8601String().split('T')[0],
      if (dateTo != null) 'date_to': dateTo.toIso8601String().split('T')[0],
      if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
    };
    final hasFilters = queryParameters.isNotEmpty;
    final cacheKey = hasFilters
        ? 'contributions:${queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : 'contributions';

    return await _getWithCache(
      'finance/contributions/',
      customCacheKey: cacheKey,
      queryParameters: hasFilters ? queryParameters : null,
    );
  }

  Future<Response> proposeManualContribution(
      Map<String, dynamic> proposalData) async {
    return await _executeWithOfflineQueue('POST', 'finance/contributions/',
        data: proposalData);
  }

  Future<Response> getPenalties() async {
    return await _getWithCache('finance/penalties/',
        customCacheKey: 'penalties');
  }

  Future<Response> getInvestments({
    int? groupId,
    int? cycleId,
    String? status,
    String? category,
    String? riskLevel,
    String? member,
    double? amountMin,
    double? amountMax,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return await _getWithCache(
      'finance/investments/',
      queryParameters: {
        if (groupId != null) 'group_id': groupId,
        if (cycleId != null) 'cycle_id': cycleId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (category != null && category.isNotEmpty) 'category': category,
        if (riskLevel != null && riskLevel.isNotEmpty) 'risk_level': riskLevel,
        if (member != null && member.isNotEmpty) 'member': member,
        if (amountMin != null) 'amount_min': amountMin,
        if (amountMax != null) 'amount_max': amountMax,
        if (dateFrom != null)
          'date_from': dateFrom.toIso8601String().split('T')[0],
        if (dateTo != null) 'date_to': dateTo.toIso8601String().split('T')[0],
      },
    );
  }

  Future<Response> createInvestment(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'finance/investments/',
        data: data);
  }

  Future<Response> approveInvestment(int id, Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue(
        'POST', 'finance/investments/$id/approve/',
        data: data);
  }

  Future<Response> rejectInvestment(int id, Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue(
        'POST', 'finance/investments/$id/reject/',
        data: data);
  }

  Future<Response> issuePenalty(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'finance/penalties/',
        data: data);
  }

  // ======================
  // Admin / Governance
  // ======================

  Future<Response> getAdminStats() async {
    return await _getWithCache('accounts/admin-stats/');
  }

  Future<Response> getPendingUsers() async {
    return await _getWithCache('accounts/pending-users/');
  }

  Future<Response> getUsers({bool approvedOnly = false}) async {
    return await _getWithCache('accounts/users/', queryParameters: {
      if (approvedOnly) 'approved_only': 'true',
    });
  }

  Future<Response> adminRegisterUser(Map<String, dynamic> userData) async {
    return await _executeWithOfflineQueue(
        'POST', 'accounts/users/admin_register/',
        data: userData);
  }

  Future<Response> approveUser(int userId) async {
    return await _executeWithOfflineQueue(
        'POST', 'accounts/users/$userId/approve/');
  }

  Future<Response> rejectUser(int userId, String reason) async {
    return await _executeWithOfflineQueue(
      'POST',
      'accounts/users/$userId/reject/',
      data: {'reason': reason},
    );
  }

  Future<Response> updateUserRole(int userId, String role) async {
    return await _executeWithOfflineQueue(
      'POST',
      'accounts/users/$userId/set_role/',
      data: {'role': role},
    );
  }

  Future<Response> deleteUser(int userId) async {
    return await _executeWithOfflineQueue('DELETE', 'accounts/users/$userId/');
  }

  Future<Response> deleteSelfAccount() async {
    return await _executeWithOfflineQueue(
        'DELETE', 'accounts/users/delete_account/');
  }

  Future<Response> approveContribution(int id) async {
    return await _executeWithOfflineQueue(
        'POST', 'finance/contributions/$id/approve/');
  }

  Future<Response> rejectContribution(int id, String reason) async {
    return await _executeWithOfflineQueue(
      'POST',
      'finance/contributions/$id/reject/',
      data: {'reason': reason},
    );
  }

  Future<Response> updateContribution(int id, Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('PATCH', 'finance/contributions/$id/',
        data: data);
  }

  Future<Response> archiveContribution(int id, String reason) async {
    return await _executeWithOfflineQueue(
      'DELETE',
      'finance/contributions/$id/',
      data: {'reason': reason},
    );
  }

  Future<Response> archivePenalty(int id, String reason) async {
    return await _executeWithOfflineQueue(
      'DELETE',
      'finance/penalties/$id/',
      data: {'reason': reason},
    );
  }

  Future<Response> getAuditLogs() async {
    return await _getWithCache('notifications/notifications/');
  }

  Future<Response> adminAddContribution(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue(
        'POST', 'finance/admin-add-contribution/',
        data: data);
  }

  Future<Response> resetFinanceHistory(
      int userId, bool resetAccountStatus) async {
    await _ensureOnline();
    return await dio.post('finance/admin-reset-member-finance/', data: {
      'user_id': userId,
      'reset_account_status': resetAccountStatus,
    });
  }

  Future<Response> getAutoSavingConfigs() async {
    return await _getWithCache('finance/auto-savings/');
  }

  Future<Response> createAutoSavingConfig(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'finance/auto-savings/',
        data: data);
  }

  Future<Response> updateAutoSavingConfig(
      int id, Map<String, dynamic> data) async {
    return await dio.patch('finance/auto-savings/$id/', data: data);
  }

  Future<Response> deleteAutoSavingConfig(int id) async {
    return await _executeWithOfflineQueue(
        'DELETE', 'finance/auto-savings/$id/');
  }

  Future<Response> getSavingsTargets() async {
    return await _getWithCache('finance/targets/');
  }

  Future<Response> createSavingsTarget(Map<String, dynamic> data) async {
    return await _executeWithOfflineQueue('POST', 'finance/targets/',
        data: data);
  }

  Future<Response> updateSavingsTarget(
      int id, Map<String, dynamic> data) async {
    return await dio.patch('finance/targets/$id/', data: data);
  }

  Future<Response> deleteSavingsTarget(int id) async {
    return await _executeWithOfflineQueue('DELETE', 'finance/targets/$id/');
  }

  Future<Response> getFinancialInsights() async {
    return await _getWithCache('finance/insights/');
  }

  Future<Response> getFinancialCycles({int? groupId, String? status}) async {
    return await _getWithCache('finance/financial-cycles/', queryParameters: {
      if (groupId != null) 'group_id': groupId,
      if (status != null && status.isNotEmpty) 'status': status,
    });
  }

  Future<Response> getMonthlyContributionRecords({
    int? groupId,
    int? cycleId,
    int? memberId,
    String? status,
    DateTime? month,
  }) async {
    return await _getWithCache('finance/monthly-contributions/',
        queryParameters: {
          if (groupId != null) 'group_id': groupId,
          if (cycleId != null) 'cycle_id': cycleId,
          if (memberId != null) 'member_id': memberId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (month != null) 'month': month.toIso8601String().split('T')[0],
        });
  }

  Future<Response> exportMonthlyContributionRecords({
    int? groupId,
    int? cycleId,
    int? memberId,
    String? status,
    DateTime? month,
  }) async {
    return await dio.get(
      'finance/monthly-contributions/export/',
      queryParameters: {
        if (groupId != null) 'group_id': groupId,
        if (cycleId != null) 'cycle_id': cycleId,
        if (memberId != null) 'member_id': memberId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (month != null) 'month': month.toIso8601String().split('T')[0],
      },
      options: Options(responseType: ResponseType.plain),
    );
  }

  Future<Response> getCycleAnnualSummary(int cycleId) async {
    return await _getWithCache('finance/reports/annual/', queryParameters: {
      'cycle_id': cycleId,
    });
  }

  Future<Response> getMonthlyReport(
    int groupId,
    int month,
    int year, {
    int? cycleId,
  }) async {
    return await _getWithCache('finance/reports/summary/', queryParameters: {
      'group_id': groupId,
      'month': month,
      'year': year,
      if (cycleId != null) 'cycle_id': cycleId,
    });
  }

  Future<Response> getMemberAnalytics({int? groupId, int? cycleId}) async {
    return await _getWithCache('finance/analytics/member/', queryParameters: {
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
    });
  }

  Future<Response> getGroupAnalytics(int groupId, {int? cycleId}) async {
    return await _getWithCache('finance/analytics/group/', queryParameters: {
      'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
    });
  }

  Future<Response> getGroups() async {
    return await _getWithCache('groups/groups/');
  }

  Future<Response> getAdminMemberships({
    int? groupId,
    int? cycleId,
    String? search,
  }) async {
    return await _getWithCache('finance/admin-member-list/', queryParameters: {
      if (groupId != null) 'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
  }

  Future<Response> getAdminGroupSummary(int groupId, {int? cycleId}) async {
    return await _getWithCache('finance/admin-group-summary/',
        queryParameters: {
          'group_id': groupId,
          if (cycleId != null) 'cycle_id': cycleId,
        });
  }

  Future<Response> getAutoSaveHistory() async {
    return await _getWithCache('finance/auto-save-history/');
  }

  Future<Response> triggerAutoSave(
      {String action = 'generate', bool dryRun = false}) async {
    await _ensureOnline();
    return await dio.post('finance/trigger-auto-save/', data: {
      'action': action,
      'dry_run': dryRun,
    });
  }

  Future<Response> updateGroup(int groupId, Map<String, dynamic> data) async {
    await _ensureOnline();
    return await dio.patch('groups/groups/$groupId/', data: data);
  }

  Future<Response> getMemberships() async {
    return await _getWithCache('groups/memberships/');
  }

  Future<Response> updateMembership(
      int membershipId, Map<String, dynamic> data) async {
    await _ensureOnline();
    return await dio.patch('groups/memberships/$membershipId/', data: data);
  }

  Future<Response> deleteMembership(int membershipId) async {
    await _ensureOnline();
    return await dio.delete('groups/memberships/$membershipId/');
  }

  Future<Response> assignUserToGroup(Map<String, dynamic> data) async {
    await _ensureOnline();
    return await dio.post('groups/memberships/', data: data);
  }

  Future<Response> getFinancialSecretaryReport(int groupId,
      {int? cycleId}) async {
    return await _getWithCache('finance/reports/financial/', queryParameters: {
      'group_id': groupId,
      if (cycleId != null) 'cycle_id': cycleId,
    });
  }
}
