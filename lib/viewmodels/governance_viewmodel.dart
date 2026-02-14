import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/user.dart';
import '../data/models/investment.dart';
import '../data/models/notification.dart';

class GovernanceViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<User> _pendingUsers = [];
  List<User> get pendingUsers => _pendingUsers;
  
  List<Investment> _investments = [];
  List<Investment> get investments => _investments;
  
  List<NotificationModel> _auditLogs = [];
  List<NotificationModel> get auditLogs => _auditLogs;

  Future<void> fetchPendingUsers() async {
    _setLoading(true);
    try {
      final response = await _apiService.getPendingUsers();
      if (response.statusCode == 200) {
        final List data = response.data;
        _pendingUsers = data.map((e) => User.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching pending users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveUser(int userId) async {
    _setLoading(true);
    try {
      final response = await _apiService.approveUser(userId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _pendingUsers.removeWhere((u) => u.id == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error approving user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchInvestments() async {
    _setLoading(true);
    try {
      final response = await _apiService.getInvestments();
      if (response.statusCode == 200) {
        final List data = response.data;
        _investments = data.map((e) => Investment.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching investments: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAuditLogs() async {
    _setLoading(true);
    try {
      final response = await _apiService.getAuditLogs();
      if (response.statusCode == 200) {
        final List data = response.data;
        _auditLogs = data.map((e) => NotificationModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
