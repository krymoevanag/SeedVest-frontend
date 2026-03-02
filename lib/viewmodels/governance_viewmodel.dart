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

  List<User> _approvedUsers = [];
  List<User> get approvedUsers => _approvedUsers;

  List<Investment> _investments = [];
  List<Investment> get investments => _investments;

  List<NotificationModel> _auditLogs = [];
  List<NotificationModel> get auditLogs => _auditLogs;

  List<dynamic> _groups = [];
  List<dynamic> get groups => _groups;

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

  Future<bool> rejectUser(int userId, String reason) async {
    _setLoading(true);
    try {
      final response = await _apiService.rejectUser(userId, reason);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _pendingUsers.removeWhere((u) => u.id == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchApprovedUsers() async {
    _setLoading(true);
    try {
      final response = await _apiService.getUsers(approvedOnly: true);
      if (response.statusCode == 200) {
        final List data = response.data;
        _approvedUsers = data.map((e) => User.fromJson(e)).toList();
        await fetchGroups(); // Ensure groups are loaded for lookup
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching approved users: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRole(int userId, String newRole) async {
    _setLoading(true);
    try {
      final response = await _apiService.updateUserRole(userId, newRole);
      if (response.statusCode == 200) {
        // Refresh the list to show updated roles
        await fetchApprovedUsers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating user role: $e');
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

  Future<bool> deleteUser(int userId) async {
    _setLoading(true);
    try {
      final response = await _apiService.deleteUser(userId);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _pendingUsers.removeWhere((u) => u.id == userId);
        _approvedUsers.removeWhere((u) => u.id == userId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerMember({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final names = fullName.split(' ');
      final response = await _apiService.adminRegisterUser({
        'email': email,
        'first_name': names.first,
        'last_name': names.length > 1 ? names.sublist(1).join(' ') : '',
        'phone_number': phoneNumber,
        'role': role,
      });

      if (response.statusCode == 201) {
        await fetchApprovedUsers(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error registering member: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> issuePenalty({
    required int userId,
    required double amount,
    required String reason,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.issuePenalty({
        'user': userId,
        'amount': amount,
        'reason': reason,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchApprovedUsers(); // Refresh to update balance
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error issuing penalty: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> resetFinanceHistory(int userId, bool resetAccountStatus) async {
    _setLoading(true);
    try {
      final response =
          await _apiService.resetFinanceHistory(userId, resetAccountStatus);
      if (response.statusCode == 200) {
        await fetchApprovedUsers(); // Refresh to show cleared balances
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error resetting finance history: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<dynamic>> fetchGroups() async {
    _setLoading(true);
    try {
      final response = await _apiService.getGroups();
      if (response.statusCode == 200) {
        _groups = response.data;
        notifyListeners();
        return _groups;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching groups: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createInvestment(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.createInvestment(data);
      if (response.statusCode == 201) {
        await fetchInvestments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating investment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveInvestment(int id, {String notes = ''}) async {
    _setLoading(true);
    try {
      final response =
          await _apiService.approveInvestment(id, {'notes': notes});
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchInvestments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error approving investment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectInvestment(int id, String notes) async {
    _setLoading(true);
    try {
      final response = await _apiService.rejectInvestment(id, {'notes': notes});
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchInvestments();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error rejecting investment: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignUserToGroup({
    required int userId,
    required int groupId,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final response = await _apiService.assignUserToGroup({
        'user': userId,
        'group': groupId,
        'role': role,
      });
      if (response.statusCode == 201) {
        await fetchApprovedUsers(); // Refresh the list
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error assigning user to group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
