import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/user.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.get('/accounts/users/me/');
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      // For demo/dev purposes, if /me/ doesn't exist yet, we might fallback or set a dummy
    } finally {
      _setLoading(false);
    }
  }

  // Helper getters for roles
  bool get isAdmin => _currentUser?.role == 'ADMIN';
  bool get isTreasurer => _currentUser?.role == 'TREASURER' || isAdmin;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
