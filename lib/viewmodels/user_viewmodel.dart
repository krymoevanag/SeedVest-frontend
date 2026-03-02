import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/network/api_service.dart';
import '../data/models/user.dart';
import '../core/services/inactivity_service.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _setLoading(true);
    try {
      final response = await _apiService.dio.get('accounts/users/me/');
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        // Start inactivity service once profile is successfully loaded
        InactivityService.instance.start();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      // For demo/dev purposes, if /me/ doesn't exist yet, we might fallback or set a dummy
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.updateProfile(data);
      if (response.statusCode == 200) {
        // Refresh local user data
        _currentUser = User.fromJson(response.data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfilePicture(String filePath) async {
    _setLoading(true);
    try {
      final response = await _apiService.updateProfilePicture(filePath);
      if (response.statusCode == 200) {
        _currentUser = User.fromJson(response.data);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    _setLoading(true);
    try {
      final token = await _apiService.storage.read(key: 'access_token');
      if (token == null) return false;

      await fetchProfile();
      return _currentUser != null;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      // Stop inactivity service on logout
      InactivityService.instance.stop();
      await _apiService.logout();
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    try {
      final response = await _apiService.deleteSelfAccount();
      if (response.statusCode == 204 || response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return response;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isBiometricEnabled() async {
    return await _apiService.isBiometricEnabled();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _apiService.setBiometricEnabled(enabled);
  }

  // Helper getters for roles
  bool get isAdmin =>
      _currentUser?.role == 'ADMIN' || (_currentUser?.isSuperuser ?? false);
  bool get isTreasurer => _currentUser?.role == 'TREASURER' || isAdmin;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
