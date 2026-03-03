import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoad();
    });
  }

  void _initialLoad() async {
    final governanceVM = context.read<GovernanceViewModel>();
    final groups = await governanceVM.fetchGroups();
    if (groups.isNotEmpty && mounted) {
      setState(() {
        _selectedGroupId = groups.first['id'];
      });
      _loadData();
    }
  }

  void _loadData() {
    final financeVM = context.read<FinanceViewModel>();
    financeVM.fetchMemberAnalytics(groupId: _selectedGroupId);

    final userVM = context.read<UserViewModel>();
    if ((userVM.isAdmin || userVM.isTreasurer) && _selectedGroupId != null) {
      financeVM.fetchGroupAnalytics(_selectedGroupId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final governanceVM = context.watch<GovernanceViewModel>();
    final isAdmin = userVM.isAdmin || userVM.isTreasurer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          if (governanceVM.groups.isNotEmpty)
            DropdownButton<int>(
              value: _selectedGroupId,
              underline: const SizedBox(),
              icon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.filter_list, color: Colors.white),
              ),
              selectedItemBuilder: (context) {
                return governanceVM.groups.map((group) {
                  return Center(
                    child: Text(
                      group['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList();
              },
              items: governanceVM.groups.map<DropdownMenuItem<int>>((group) {
                return DropdownMenuItem<int>(
                  value: group['id'],
                  child: Text(group['name']),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _selectedGroupId = newValue;
                });
                _loadData();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Overview'),
            const Tab(text: 'Performance'),
            const Tab(text: 'Investments'),
            if (isAdmin) const Tab(text: 'Group Analysis'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildPerformanceTab(),
          _buildInvestmentsTab(),
          if (isAdmin) _buildGroupAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<FinanceViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.memberAnalytics == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final analytics = viewModel.memberAnalytics?['core_metrics'];
        if (analytics == null) {
          return const Center(child: Text('No analytics data available.'));
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Personal Financial Health'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Total Invested',
                    value: 'KSh ${analytics['total_invested']}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                  StatCard(
                    title: 'Returns Earned',
                    value: 'KSh ${analytics['total_returns']}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  StatCard(
                    title: 'Total Savings',
                    value: 'KSh ${analytics['total_savings']}',
                    icon: Icons.savings_outlined,
                    color: Colors.blue,
                  ),
                  StatCard(
                    title: 'ROI %',
                    value: '${analytics['roi_percentage']}%',
                    icon: Icons.pie_chart_outline,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Consistency Score'),
              const SizedBox(height: 8),
              _buildConsistencyIndicator(analytics['consistency_score']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return Consumer<FinanceViewModel>(
      builder: (context, viewModel, child) {
        final trends = viewModel.memberAnalytics?['trends']?['growth'] as List?;
        if (trends == null || trends.isEmpty) {
          return const Center(child: Text('Performance trends not available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Growth Over Time'),
              const SizedBox(height: 24),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(trends.length, (index) {
                          final val = double.tryParse(
                                  trends[index]['total'].toString()) ??
                              0.0;
                          return FlSpot(index.toDouble(), val);
                        }),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('Last 6 Months Projection')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvestmentsTab() {
    return Consumer<FinanceViewModel>(
      builder: (context, viewModel, child) {
        final dist =
            viewModel.memberAnalytics?['distributions']?['category'] as List?;
        if (dist == null || dist.isEmpty) {
          return const Center(
              child: Text('Investment distribution not available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSectionTitle('Portfolio by Category'),
              const SizedBox(height: 32),
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: dist.map((d) {
                      final val = double.tryParse(d['value'].toString()) ?? 0.0;
                      return PieChartSectionData(
                        value: val,
                        title: d['category'] ?? 'Other',
                        radius: 100,
                        titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        color: Colors.primaries[
                            dist.indexOf(d) % Colors.primaries.length],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupAnalysisTab() {
    return Consumer<FinanceViewModel>(
      builder: (context, viewModel, child) {
        final groupStats = viewModel.groupAnalytics?['group_metrics'];
        if (groupStats == null) {
          return const Center(
              child: Text('Select a group to view aggregate analytics.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Group Distribution'),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  title: 'Total Capital',
                  value: 'KSh ${groupStats['total_capital']}',
                  icon: Icons.business_center_outlined,
                  color: AppColors.primary,
                ),
                StatCard(
                  title: 'Active Members',
                  value: groupStats['active_members'].toString(),
                  icon: Icons.people_outline,
                  color: Colors.blue,
                ),
                StatCard(
                  title: 'Approval Ratio',
                  value: '${groupStats['approval_ratio']}%',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Pending Proposals',
                  value: groupStats['pending_proposals'].toString(),
                  icon: Icons.history_edu,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildConsistencyIndicator(dynamic score) {
    final val = (double.tryParse(score.toString()) ?? 0.0) / 100;
    Color color = Colors.red;
    if (val > 0.8) {
      color = Colors.green;
    } else if (val > 0.5) {
      color = Colors.orange;
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: val,
          backgroundColor: Colors.grey.shade200,
          color: color,
          minHeight: 12,
          borderRadius: BorderRadius.circular(6),
        ),
        const SizedBox(height: 8),
        Text('Reliability Score: $score%',
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
