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

    int? resolvedUserId = userId;

    try {
      // If userId wasn't provided, attempt to resolve from profile
      if (resolvedUserId == null) {
        try {
          final profileResp = await _apiService.getProfile();
          if (profileResp.statusCode == 200 && profileResp.data is Map) {
            resolvedUserId = profileResp.data['id'] as int?;
          }
        } catch (_) {}
      }

      // Fetch contributions
      try {
        final contribResp = await _apiService.getContributions();
        if (contribResp.statusCode == 200 && contribResp.data is List) {
          final List data = contribResp.data;
          _recentContributions =
              data.map((e) => Contribution.fromJson(e)).toList();

          _totalSavings = _recentContributions
              .where((c) => c.status == 'PAID' || c.status == 'LATE')
              .fold(0.0, (sum, item) => sum + item.amount);
        }
      } catch (e) {
        debugPrint('Error loading contributions for dashboard: $e');
      }

      // Fetch multi-type savings/activity history
      if (resolvedUserId != null) {
        try {
          final histResp =
              await _apiService.getMemberSavingsHistory(resolvedUserId);
          if (histResp.statusCode == 200 && histResp.data is List) {
            final dynamic histData = histResp.data;
            _recentActivities = histData
                .take(5)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
          }
        } catch (e) {
          debugPrint('Error loading member savings history: $e');
        }
      }

      // Fetch group summary
      await _fetchGroupSummary();
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
            _groupBalance = double.tryParse(
                    (stats['group_balance'] ?? stats['total_savings'] ?? 0)
                        .toString()) ??
                0.0;
            _groupMemberCount =
                int.tryParse((stats['member_count'] ?? 0).toString()) ?? 0;
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
