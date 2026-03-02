import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class FinanceViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _insights;
  Map<String, dynamic>? get insights => _insights;

  Map<String, dynamic>? _memberAnalytics;
  Map<String, dynamic>? get memberAnalytics => _memberAnalytics;

  Map<String, dynamic>? _groupAnalytics;
  Map<String, dynamic>? get groupAnalytics => _groupAnalytics;

  List<dynamic> _savingsTargets = [];
  List<dynamic> get savingsTargets => _savingsTargets;

  List<dynamic> _autoSavingConfigs = [];
  List<dynamic> get autoSavingConfigs => _autoSavingConfigs;

  Map<String, dynamic>? _monthlyReport;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;

  List<dynamic> _adminMemberships = [];
  List<dynamic> get adminMemberships => _adminMemberships;

  Map<String, dynamic>? _adminGroupSummary;
  Map<String, dynamic>? get adminGroupSummary => _adminGroupSummary;

  List<dynamic> _autoSaveHistory = [];
  List<dynamic> get autoSaveHistory => _autoSaveHistory;

  List<dynamic> _memberships = [];
  List<dynamic> get memberships => _memberships;

  int? _selectedGroupId;
  int? get selectedGroupId => _selectedGroupId;

  Future<void> fetchInsights() async {
    _setLoading(true);
    try {
      final response = await _apiService.getFinancialInsights();
      if (response.statusCode == 200) {
        _insights = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching insights: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMemberAnalytics({int? groupId}) async {
    _setLoading(true);
    try {
      final response = await _apiService.getMemberAnalytics(groupId: groupId);
      if (response.statusCode == 200) {
        _memberAnalytics = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching member analytics: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchGroupAnalytics(int groupId) async {
    _setLoading(true);
    try {
      final response = await _apiService.getGroupAnalytics(groupId);
      if (response.statusCode == 200) {
        _groupAnalytics = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching group analytics: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchSavingsTargets() async {
    _setLoading(true);
    try {
      final response = await _apiService.getSavingsTargets();
      if (response.statusCode == 200) {
        _savingsTargets = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching savings targets: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createSavingsTarget(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.createSavingsTarget(data);
      if (response.statusCode == 201) {
        await fetchSavingsTargets();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating savings target: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAutoSavingConfigs() async {
    _setLoading(true);
    try {
      final response = await _apiService.getAutoSavingConfigs();
      if (response.statusCode == 200) {
        _autoSavingConfigs = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching auto-saving configs: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAutoSavingConfig(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.createAutoSavingConfig(data);
      if (response.statusCode == 201) {
        await fetchAutoSavingConfigs();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error creating auto-saving config: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateAutoSavingConfig(int id, bool isActive) async {
    _setLoading(true);
    try {
      final response =
          await _apiService.updateAutoSavingConfig(id, {'is_active': isActive});
      if (response.statusCode == 200) {
        await fetchAutoSavingConfigs();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating auto-saving config: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMonthlyReport(int groupId, int month, int year) async {
    _setLoading(true);
    try {
      final response = await _apiService.getMonthlyReport(groupId, month, year);
      if (response.statusCode == 200) {
        _monthlyReport = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching monthly report: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAdminMemberships({String? search}) async {
    _setLoading(true);
    try {
      final response = await _apiService.getAdminMemberships(
        groupId: _selectedGroupId,
        search: search,
      );
      if (response.statusCode == 200) {
        _adminMemberships = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching admin memberships: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAdminGroupSummary() async {
    if (_selectedGroupId == null) return;
    _setLoading(true);
    try {
      final response =
          await _apiService.getAdminGroupSummary(_selectedGroupId!);
      if (response.statusCode == 200) {
        _adminGroupSummary = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching admin group summary: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedGroup(int? groupId) {
    _selectedGroupId = groupId;
    _adminGroupSummary = null;
    fetchAdminMemberships();
    if (groupId != null) {
      fetchAdminGroupSummary();
    }
    notifyListeners();
  }

  Future<bool> adminAddContribution(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.adminAddContribution(data);
      if (response.statusCode == 201) {
        await fetchAdminMemberships();
        await fetchAdminGroupSummary();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in adminAddContribution: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> adminIssuePenalty(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.issuePenalty(data);
      if (response.statusCode == 201) {
        await fetchAdminMemberships();
        await fetchAdminGroupSummary();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error in adminIssuePenalty: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchAutoSaveHistory() async {
    _setLoading(true);
    try {
      final response = await _apiService.getAutoSaveHistory();
      if (response.statusCode == 200) {
        _autoSaveHistory = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching auto-save history: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> triggerAutoSave(
      {String action = 'generate', bool dryRun = false}) async {
    _setLoading(true);
    try {
      final response = await _apiService.triggerAutoSave(
        action: action,
        dryRun: dryRun,
      );
      if (response.statusCode == 200 || response.statusCode == 207) {
        await fetchAutoSaveHistory();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error triggering auto-save: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchMemberships() async {
    _setLoading(true);
    try {
      final response = await _apiService.getMemberships();
      if (response.statusCode == 200) {
        _memberships = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching memberships: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateMembership(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.updateMembership(id, data);
      if (response.statusCode == 200) {
        await fetchMemberships();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating membership: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateGroupSettings(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      final response = await _apiService.updateGroup(id, data);
      if (response.statusCode == 200) {
        // Refresh stats if needed, or just specific group cache
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating group settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
