import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/colors.dart';
import 'package:intl/intl.dart';

class FinancialReportsView extends StatefulWidget {
  const FinancialReportsView({super.key});

  @override
  State<FinancialReportsView> createState() => _FinancialReportsViewState();
}

class _FinancialReportsViewState extends State<FinancialReportsView> {
  int? _selectedGroupId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final groups = await context.read<GovernanceViewModel>().fetchGroups();
      if (groups.isNotEmpty) {
        setState(() {
          _selectedGroupId = groups.first.id;
        });
        _fetchReport();
      }
    });
  }

  void _fetchReport() {
    if (_selectedGroupId != null) {
      context.read<FinanceViewModel>().fetchMonthlyReport(
            _selectedGroupId!,
            _selectedMonth,
            _selectedYear,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<FinanceViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final report = viewModel.monthlyReport;
                if (report == null) {
                  return const Center(
                      child: Text('Select filters and fetch report.'));
                }

                return _buildReportContent(report);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Consumer<GovernanceViewModel>(
            builder: (context, gViewModel, child) {
              return DropdownButtonFormField<int>(
                initialValue: _selectedGroupId,
                decoration: const InputDecoration(labelText: 'Select Group'),
                items: gViewModel.groups.map((g) {
                  return DropdownMenuItem<int>(
                    value: g.id,
                    child: Text(g.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedGroupId = val);
                  _fetchReport();
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: const InputDecoration(labelText: 'Month'),
                  items: List.generate(12, (index) => index + 1).map((m) {
                    return DropdownMenuItem<int>(
                      value: m,
                      child: Text(DateFormat('MMMM').format(DateTime(2024, m))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedMonth = val!);
                    _fetchReport();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: [2024, 2025, 2026].map((y) {
                    return DropdownMenuItem<int>(
                      value: y,
                      child: Text(y.toString()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedYear = val!);
                    _fetchReport();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Savings',
          'UGX ${report['total_savings']}',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildStatCard(
          'Total Penalties',
          'UGX ${report['total_penalties']}',
          Icons.gavel_rounded,
          Colors.red,
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                'UGX ${report['pending_amount']}',
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                'UGX ${report['overdue_amount']}',
                Icons.error_outline,
                Colors.red.shade900,
              ),
            ),
          ],
        ),
        _buildStatCard(
          'Collection Rate',
          '${report['collection_rate']}%',
          Icons.percent,
          Colors.blue,
        ),
        _buildStatCard(
          'Active Investments',
          report['active_investments_count'].toString(),
          Icons.trending_up,
          Colors.purple,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            // Placeholder for CSV Export
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV Export coming soon!')),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
