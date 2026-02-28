import 'package:flutter/material.dart';
import '../core/network/api_service.dart';

class FinanceViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _insights;
  Map<String, dynamic>? get insights => _insights;

  List<dynamic> _savingsTargets = [];
  List<dynamic> get savingsTargets => _savingsTargets;

  List<dynamic> _autoSavingConfigs = [];
  List<dynamic> get autoSavingConfigs => _autoSavingConfigs;

  Map<String, dynamic>? _monthlyReport;
  Map<String, dynamic>? get monthlyReport => _monthlyReport;

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
