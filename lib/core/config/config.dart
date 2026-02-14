import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized application configuration
class AppConfig {
  /// API base URL from environment
  static String get apiUrl => dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';
  
  /// Current environment (development, staging, production)
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  
  /// Whether offline mode is enabled
  static bool get isOfflineModeEnabled => 
      dotenv.env['ENABLE_OFFLINE_MODE'] == 'true';
  
  /// Whether debug logging is enabled
  static bool get isDebugLoggingEnabled => 
      dotenv.env['ENABLE_DEBUG_LOGGING'] == 'true';
  
  /// Check if running in development mode
  static bool get isDevelopment => environment == 'development';
  
  /// Check if running in production mode
  static bool get isProduction => environment == 'production';
}
