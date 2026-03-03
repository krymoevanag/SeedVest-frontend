import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
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
  int? _selectedCycleId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final groups = await context.read<GovernanceViewModel>().fetchGroups();
      if (groups.isNotEmpty) {
        setState(() {
          _selectedGroupId = groups.first['id'];
        });
        await _loadCyclesForGroup();
        await _fetchReport();
      }
    });
  }

  Future<void> _loadCyclesForGroup() async {
    if (_selectedGroupId == null) {
      return;
    }
    final financeVM = context.read<FinanceViewModel>();
    await financeVM.fetchFinancialCycles(groupId: _selectedGroupId!);
    if (!mounted) {
      return;
    }
    final cycles = financeVM.financialCycles;
    final active = cycles
        .where((cycle) => cycle.status.toUpperCase() == 'ACTIVE')
        .toList(growable: false);
    setState(() {
      _selectedCycleId = active.isNotEmpty
          ? active.first.id
          : (cycles.isNotEmpty ? cycles.first.id : null);
    });
  }

  Future<void> _fetchReport() async {
    if (_selectedGroupId == null) {
      return;
    }
    final financeVM = context.read<FinanceViewModel>();
    final monthDate = DateTime(_selectedYear, _selectedMonth, 1);

    await financeVM.fetchMonthlyReport(
      _selectedGroupId!,
      _selectedMonth,
      _selectedYear,
      cycleId: _selectedCycleId,
    );
    if (!mounted) {
      return;
    }
    await financeVM.fetchMonthlyContributionRecords(
      groupId: _selectedGroupId,
      cycleId: _selectedCycleId,
      month: monthDate,
    );
    if (!mounted) {
      return;
    }
    if (_selectedCycleId != null) {
      await financeVM.fetchAnnualCycleSummary(_selectedCycleId!);
    } else {
      financeVM.setSelectedCycle(null);
    }
  }

  Future<void> _exportCsv() async {
    if (_selectedGroupId == null) {
      return;
    }
    try {
      final response = await _apiService.exportMonthlyContributionRecords(
        groupId: _selectedGroupId,
        cycleId: _selectedCycleId,
        month: DateTime(_selectedYear, _selectedMonth, 1),
      );
      final csv = response.data?.toString() ?? '';
      final rows = csv
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .length;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export fetched (${rows > 0 ? rows - 1 : 0} rows).'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to export monthly contributions CSV.'),
          backgroundColor: Colors.red,
        ),
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
      body: Consumer<FinanceViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildFilters(viewModel),
              Expanded(
                child: viewModel.isLoading &&
                        viewModel.monthlyReport == null &&
                        viewModel.monthlyContributionRecords.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildReportContent(viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters(FinanceViewModel financeVM) {
    final cycles = financeVM.financialCycles;
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
                    value: g['id'],
                    child: Text(g['name']),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedGroupId = val;
                    _selectedCycleId = null;
                  });
                  _loadCyclesForGroup().then((_) => _fetchReport());
                },
              );
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _selectedCycleId,
            decoration: const InputDecoration(labelText: 'Financial Cycle'),
            items: cycles
                .map(
                  (cycle) => DropdownMenuItem<int>(
                    value: cycle.id,
                    child: Text('${cycle.cycleName} (${cycle.status})'),
                  ),
                )
                .toList(),
            onChanged: cycles.isEmpty
                ? null
                : (val) {
                    setState(() => _selectedCycleId = val);
                    _fetchReport();
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
                      child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
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
                  items: [2024, 2025, 2026, 2027].map((y) {
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

  Widget _buildReportContent(FinanceViewModel viewModel) {
    final report = viewModel.monthlyReport;
    if (report == null) {
      return const Center(child: Text('Select filters and fetch report.'));
    }
    final annual = viewModel.annualCycleSummary;
    final monthlyRecords = viewModel.monthlyContributionRecords;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Savings',
          'KES ${report['total_savings']}',
          Icons.account_balance_wallet,
          Colors.green,
        ),
        _buildStatCard(
          'Total Penalties',
          'KES ${report['total_penalties']}',
          Icons.gavel_rounded,
          Colors.red,
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                'KES ${report['pending_amount']}',
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Overdue',
                'KES ${report['overdue_amount']}',
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
          'Expected Contributions',
          'KES ${report['total_expected_contributions']}',
          Icons.calendar_month,
          Colors.blueGrey,
        ),
        _buildStatCard(
          'Collected Contributions',
          'KES ${report['total_collected_contributions']}',
          Icons.savings,
          Colors.teal,
        ),
        _buildStatCard(
          'Outstanding Totals',
          'KES ${report['outstanding_totals']}',
          Icons.warning_amber_rounded,
          Colors.deepOrange,
        ),
        _buildStatCard(
          'Active Investments',
          report['active_investments_count'].toString(),
          Icons.trending_up,
          Colors.purple,
        ),
        if (annual != null) ...[
          const SizedBox(height: 8),
          Text(
            'Cycle Annual Summary',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _buildStatCard(
            'Fulfillment Rate',
            '${annual['contribution_fulfillment_rate']}%',
            Icons.track_changes,
            Colors.indigo,
          ),
          _buildStatCard(
            'Consistency Score',
            '${annual['member_payment_consistency_score']}%',
            Icons.verified_user,
            Colors.green,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Monthly Member Records',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (monthlyRecords.isEmpty)
          const Text('No monthly records for selected filters.')
        else
          ...monthlyRecords.map(
            (record) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(record.memberName),
                subtitle: Text(
                  '${record.cycleName} • ${DateFormat('MMM yyyy').format(record.month)}',
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      record.status,
                      style: TextStyle(
                        color: record.status == 'PAID'
                            ? Colors.green
                            : (record.status == 'PARTIAL'
                                ? Colors.orange
                                : Colors.red),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'KES ${record.actualContributionPaid}/${record.expectedContributionAmount}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (record.outstandingAmount > 0)
                      Text(
                        'Out: KES ${record.outstandingAmount}',
                        style: const TextStyle(fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _exportCsv,
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
