import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages an inactivity timer for automatic session logout.
///
/// - timeout:        10 minutes of no user activity → triggers [onTimeout]
/// - warningBefore:  60 seconds before timeout     → triggers [onWarning]
///
/// Call [resetTimer] on every user interaction (pointer event).
/// Call [stop] when the user is on a public screen (login, onboarding).
class InactivityService {
  InactivityService._internal();
  static final InactivityService instance = InactivityService._internal();

  // Configurable durations
  static const Duration _timeout = Duration(minutes: 10);
  static const Duration _warningBefore = Duration(minutes: 1); // 9m + 1m = 10m
  static Duration get warningDuration => _warningBefore;

  Timer? _idleTimer;
  Timer? _warningTimer;

  /// Called 60 seconds before auto-logout.
  VoidCallback? onWarning;

  /// Called when the session has timed out due to inactivity.
  VoidCallback? onTimeout;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Start or reset the inactivity countdown.
  void resetTimer() {
    if (!_isRunning) return;
    _idleTimer?.cancel();
    _warningTimer?.cancel();

    // Schedule warning 60 s before full timeout
    _warningTimer = Timer(_timeout - _warningBefore, () {
      onWarning?.call();
    });

    // Schedule the actual logout
    _idleTimer = Timer(_timeout, () {
      onTimeout?.call();
    });
  }

  /// Start/activate the service (call after successful login).
  void start() {
    _isRunning = true;
    resetTimer();
  }

  /// Pause/stop the service (call on logout or public screens).
  void stop() {
    _isRunning = false;
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _idleTimer = null;
    _warningTimer = null;
  }
}
