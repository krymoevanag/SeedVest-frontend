import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged => _controller.stream;
  
  /// Check if device is currently connected to internet
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.first != ConnectivityResult.none;
  }
  
  /// Initialize connectivity monitoring
  void init() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.first != ConnectivityResult.none;
      _controller.add(isConnected);
    });
  }
  
  /// Dispose resources
  void dispose() {
    _controller.close();
  }
}
