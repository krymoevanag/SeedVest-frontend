import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../data/models/contribution.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  double _totalSavings = 0.0;
  double get totalSavings => _totalSavings;
  
  List<Contribution> _recentContributions = [];
  List<Contribution> get recentContributions => _recentContributions;

  
  // Admin Stats
  Map<String, dynamic> _adminStats = {};
  Map<String, dynamic> get adminStats => _adminStats;

  Future<void> fetchDashboardData() async {
    _setLoading(true);
    try {
      final response = await _apiService.getContributions();
      if (response.statusCode == 200) {
        final List data = response.data;
        _recentContributions = data.map((e) => Contribution.fromJson(e)).toList();
        
        // Calculate total savings from contributions
        _totalSavings = _recentContributions
            .where((c) => c.status == 'SUCCESS')
            .fold(0.0, (sum, item) => sum + item.amount);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAdminStats() async {
    _setLoading(true);
    try {
      final response = await _apiService.getAdminStats();
      if (response.statusCode == 200) {
        _adminStats = response.data;
      }
    } catch (e) {
      debugPrint('Error fetching admin stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
