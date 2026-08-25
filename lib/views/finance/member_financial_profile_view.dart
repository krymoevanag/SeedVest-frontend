import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/user_viewmodel.dart';

class MemberFinancialProfileView extends StatefulWidget {
  const MemberFinancialProfileView({super.key, this.memberId});

  final int? memberId;

  @override
  State<MemberFinancialProfileView> createState() =>
      _MemberFinancialProfileViewState();
}

class _MemberFinancialProfileViewState
    extends State<MemberFinancialProfileView> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final memberId =
        widget.memberId ?? context.read<UserViewModel>().currentUser?.id;
    if (memberId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Member profile is unavailable.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getMemberFinancialProfile(memberId);
      if (!mounted) return;
      setState(() => _profile = Map<String, dynamic>.from(response.data));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load the financial profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _number(String key) => (_profile?[key] as num?)?.toDouble() ?? 0;

  String _money(String key) => 'KES ${_number(key).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final member = Map<String, dynamic>.from(_profile?['member'] ?? {});
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial profile'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadProfile)
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        member['name']?.toString() ?? 'Member',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (member['membership_number'] != null)
                        Text(member['membership_number'].toString()),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.55,
                        children: [
                          _MetricCard(
                              'Savings', _money('total_savings'), Colors.green),
                          _MetricCard('Penalties', _money('total_penalties'),
                              Colors.orange),
                          _MetricCard('Investments',
                              _money('total_investments'), Colors.blue),
                          _MetricCard('Outstanding',
                              _money('outstanding_balance'), Colors.red),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _DetailRow(
                          'Total contributions', _money('total_contributions')),
                      _DetailRow(
                          'Verified repayments', _money('total_repayments')),
                      _DetailRow(
                          'Active loans', '${_profile?['active_loans'] ?? 0}'),
                      _DetailRow('Overdue loans',
                          '${_profile?['overdue_loans'] ?? 0}'),
                      _DetailRow('Overdue balance', _money('overdue_balance')),
                      _DetailRow('Net position', _money('net_position')),
                    ],
                  ),
                ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: color),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing:
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
