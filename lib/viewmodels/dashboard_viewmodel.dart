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

  List<Map<String, dynamic>> _recentActivities = [];
  List<Map<String, dynamic>> get recentActivities => _recentActivities;

  // Group Summary for members
  String? _groupName;
  String? get groupName => _groupName;

  double _groupBalance = 0.0;
  double get groupBalance => _groupBalance;

  int _groupMemberCount = 0;
  int get groupMemberCount => _groupMemberCount;

  // Admin Stats
  Map<String, dynamic> _adminStats = {};
  Map<String, dynamic> get adminStats => _adminStats;

  String? _error;
  String? get error => _error;

  Future<void> fetchDashboardData({int? userId}) async {
    _setLoading(true);
    _error = null;
    try {
      final futures = <Future>[
        _apiService.getContributions(),
      ];

      if (userId != null) {
        futures.add(_apiService.getMemberSavingsHistory(userId));
      }

      // Also attempt to fetch memberships to resolve group balance
      futures.add(_fetchGroupSummary());

      final results = await Future.wait(futures);

      // Handle contributions response
      final contribResp = results[0];
      if (contribResp.statusCode == 200) {
        final List data = contribResp.data;
        _recentContributions =
            data.map((e) => Contribution.fromJson(e)).toList();

        _totalSavings = _recentContributions
            .where((c) => c.status == 'PAID' || c.status == 'LATE')
            .fold(0.0, (sum, item) => sum + item.amount);
      }

      // Handle recent activities response if fetched
      if (userId != null && results.length > 1 && results[1].statusCode == 200) {
        final dynamic histData = results[1].data;
        if (histData is List) {
          _recentActivities = histData
              .take(5)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (e) {
      _error = 'Failed to load dashboard data';
      debugPrint('Error fetching dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchGroupSummary() async {
    try {
      final memResp = await _apiService.getMemberships();
      final memberships = memResp.data is List ? memResp.data as List : [];
      if (memberships.isNotEmpty) {
        final first = Map<String, dynamic>.from(memberships.first);
        final groupId = first['group'] as int?;
        _groupName = first['group_name']?.toString() ?? 'My Group';

        if (groupId != null) {
          final sumResp = await _apiService.getGroupSummary(groupId);
          if (sumResp.statusCode == 200 && sumResp.data is Map) {
            final data = Map<String, dynamic>.from(sumResp.data);
            _groupName = data['group_name']?.toString() ?? _groupName;
            final stats = Map<String, dynamic>.from(data['stats'] ?? {});
            _groupBalance = (stats['group_balance'] as num?)?.toDouble() ??
                (stats['total_savings'] as num?)?.toDouble() ??
                0.0;
            _groupMemberCount = (stats['member_count'] as num?)?.toInt() ?? 0;
          }
        }
      }
    } catch (e) {
      debugPrint('Could not fetch group summary for dashboard: $e');
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
  Future<void> refreshStats({int? userId}) async {
    await Future.wait([
      fetchAdminStats(),
      fetchDashboardData(userId: userId),
    ]);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
