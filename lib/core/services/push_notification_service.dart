import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/api_service.dart';
import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _deviceToken;
  bool _initialized = false;
  bool _registerTokens = false;
  void Function(RemoteMessage message)? _onForegroundMessage;
  void Function(String? link)? _onNotificationTap;

  Future<void> initialize({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(String? link)? onNotificationTap,
  }) async {
    if (_initialized) return;

    _onForegroundMessage = onForegroundMessage;
    _onNotificationTap = onNotificationTap;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      _deviceToken = await _messaging.getToken();
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
        _deviceToken = token;
        if (_registerTokens) {
          unawaited(_registerDeviceToken(token));
        }
      });
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      _initialized = true;
      if (_registerTokens && _deviceToken != null) {
        await _registerDeviceToken(_deviceToken!);
      }
    } catch (error) {
      debugPrint('Firebase messaging is unavailable: $error');
    }
  }

  Future<void> registerCurrentDevice() async {
    _registerTokens = true;
    if (!_initialized) return;
    final token = _deviceToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _deviceToken = token;
    await _registerDeviceToken(token);
  }

  Future<void> _registerDeviceToken(String token) async {
    try {
      await _apiService.registerDeviceToken(
        deviceToken: token,
        platform: _platform,
      );
    } catch (error) {
      debugPrint('Unable to register push device token: $error');
    }
  }

  String get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.android:
        return 'ANDROID';
      default:
        return 'WEB';
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _onForegroundMessage?.call(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    _onNotificationTap?.call(message.data['link']);
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
