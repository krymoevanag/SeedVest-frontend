import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../widgets/custom_card.dart';

class FinancialSecretaryReportView extends StatefulWidget {
  const FinancialSecretaryReportView({super.key});

  @override
  State<FinancialSecretaryReportView> createState() => _FinancialSecretaryReportViewState();
}

class _FinancialSecretaryReportViewState extends State<FinancialSecretaryReportView> {
  final ApiService _apiService = ApiService();
  int? _selectedGroupId;
  int? _selectedCycleId;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final governanceVM = context.read<GovernanceViewModel>();
      final groups = await governanceVM.fetchGroups();
      if (groups.isNotEmpty && mounted) {
        setState(() {
          _selectedGroupId = groups.first['id'];
        });
        await _fetchReport();
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReport() async {
    if (_selectedGroupId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getFinancialSecretaryReport(
        _selectedGroupId!,
        cycleId: _selectedCycleId,
      );
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _reportData = response.data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch financial report')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Oversight Report'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading && _reportData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: _reportData == null
                      ? const Center(child: Text('No data available'))
                      : RefreshIndicator(
                          onRefresh: _fetchReport,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSummaryCard(currencyFormat),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Member Summaries'),
                              const SizedBox(height: 8),
                              ...(_reportData!['member_summaries'] as List? ?? [])
                                  .map((m) => _buildMemberCard(m, currencyFormat)),
                              const SizedBox(height: 24),
                              _buildSectionTitle('Monthly Trends'),
                              const SizedBox(height: 8),
                              ...(_reportData!['monthly_summaries'] as List? ?? [])
                                  .map((mo) => _buildMonthlyCard(mo, currencyFormat)),
                            ],
                          ),
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
      child: Consumer<GovernanceViewModel>(
        builder: (context, gViewModel, child) {
          return DropdownButtonFormField<int>(
            initialValue: _selectedGroupId,
            decoration: const InputDecoration(
              labelText: 'Filtered Group',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: gViewModel.groups.map((g) {
              return DropdownMenuItem<int>(
                value: g['id'],
                child: Text(g['name'] ?? 'Group ${g['id']}'),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedGroupId = val;
                _reportData = null;
              });
              _fetchReport();
            },
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(NumberFormat format) {
    final totals = _reportData!['totals'] ?? {};
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              Text(
                _reportData!['period'] ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow('Group Name', _reportData!['group_name'] ?? 'N/A'),
          const SizedBox(height: 12),
          _buildInfoRow('Total Collected', format.format(totals['total_collected'] ?? 0), isPositive: true),
          const SizedBox(height: 12),
          _buildInfoRow('Total Expected', format.format(totals['total_expected'] ?? 0)),
          const SizedBox(height: 12),
          _buildInfoRow('Total Outstanding', format.format(totals['total_outstanding'] ?? 0), isNegative: true),
          const SizedBox(height: 12),
          _buildInfoRow('Penalties Collected', format.format(totals['total_penalties'] ?? 0), color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(member['member_name'] ?? 'Unknown Member', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Paid: ${format.format(member['total_paid'] ?? 0)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Out: ${format.format(member['outstanding'] ?? 0)}',
              style: TextStyle(
                color: (member['outstanding'] ?? 0) > 0 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${member['payment_consistency'] ?? 0}% consistency',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyCard(Map<String, dynamic> month, NumberFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(month['month'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Expected: ${format.format(month['expected'] ?? 0)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  format.format(month['collected'] ?? 0),
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${month['collection_rate'] ?? 0}% Rate',
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPositive = false, bool isNegative = false, Color? color}) {
    Color valColor = color ?? AppColors.textPrimary;
    if (isPositive) valColor = Colors.green;
    if (isNegative) valColor = Colors.red;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }
}
