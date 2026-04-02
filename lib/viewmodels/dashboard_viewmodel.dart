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

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboardData() async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.getContributions();
      if (response.statusCode == 200) {
        final List data = response.data;
        _recentContributions =
            data.map((e) => Contribution.fromJson(e)).toList();

        // Calculate total savings from contributions
        _totalSavings = _recentContributions
            .where((c) => c.status == 'PAID' || c.status == 'LATE')
            .fold(0.0, (sum, item) => sum + item.amount);
      }
    } catch (e) {
      _error = 'Failed to load dashboard data';
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAdminStats() async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _apiService.getAdminStats();
      debugPrint('RAW ADMIN STATS RESPONSE: ${response.data}');
      if (response.statusCode == 200) {
        if (response.data is Map) {
          final data = Map<String, dynamic>.from(response.data as Map);

          // Defensive parsing for total users/members
          final totalUsers = data['total_users'] ??
              data['total_members'] ??
              data['members_count'] ??
              data['users_total'] ??
              0;

          data['total_users'] = totalUsers;
          _adminStats = data;
        } else {
          _adminStats = {};
        }
      }
    } catch (e) {
      _error = 'Failed to load system stats';
      debugPrint('Error fetching admin stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Centralized refresh for all dashboard stats
  Future<void> refreshStats() async {
    await Future.wait([
      fetchAdminStats(),
      fetchDashboardData(),
    ]);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
