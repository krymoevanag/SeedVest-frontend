import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';

class AdminLoanDashboardView extends StatefulWidget {
  const AdminLoanDashboardView({super.key});

  @override
  State<AdminLoanDashboardView> createState() => _AdminLoanDashboardViewState();
}

class _AdminLoanDashboardViewState extends State<AdminLoanDashboardView> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _metrics = {};
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getLoanDashboard(),
        _apiService.getOverdueLoans(),
      ]);
      if (!mounted) return;
      final metrics = Map<String, dynamic>.from(results[0].data as Map);
      final data = results[1].data is List ? results[1].data as List : const [];
      setState(() {
        _metrics = metrics;
        _loans = data.map((loan) => Map<String, dynamic>.from(loan)).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load the loan dashboard.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _money(String key) {
    final value = (_metrics[key] as num?)?.toDouble() ?? 0;
    return 'KES ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan oversight'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: FilledButton(
                    onPressed: _loadDashboard,
                    child: Text(_error!),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          _Metric('Active loans', '${_metrics['total_active_loans'] ?? 0}', Colors.blue),
                          _Metric('Due this week', '${_metrics['loans_due_this_week'] ?? 0}', Colors.orange),
                          _Metric('Disbursed', _money('total_disbursed'), Colors.green),
                          _Metric('Outstanding', _money('total_outstanding'), Colors.red),
                          _Metric('Overdue', _money('total_overdue'), Colors.deepOrange),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Overdue loans',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_loans.isEmpty)
                        const Text('No overdue loans.')
                      else
                        ..._loans.map(
                          (loan) => Card(
                            child: ListTile(
                              title: Text(loan['borrower_name']?.toString() ?? 'Loan #${loan['id']}'),
                              subtitle: Text('${loan['status'] ?? ''} | Due ${loan['due_date'] ?? 'N/A'}'),
                              trailing: Text(
                                'KES ${((loan['balance_remaining'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.color);

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
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
