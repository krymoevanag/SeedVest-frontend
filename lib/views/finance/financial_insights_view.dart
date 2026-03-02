import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../core/theme/colors.dart';

class FinancialInsightsView extends StatefulWidget {
  const FinancialInsightsView({super.key});

  @override
  State<FinancialInsightsView> createState() => _FinancialInsightsViewState();
}

class _FinancialInsightsViewState extends State<FinancialInsightsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().fetchInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Insights'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8)
              ],
            ),
          ),
        ),
      ),
      body: Consumer<FinanceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.insights == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final insights = viewModel.insights;
          if (insights == null) {
            return const Center(child: Text('No insights available yet.'));
          }

          final summaries = insights['summaries'] as List<dynamic>? ?? [];
          final recommendations =
              insights['recommendations'] as List<dynamic>? ?? [];

          return RefreshIndicator(
            onRefresh: viewModel.fetchInsights,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Your Financial Health',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...summaries.map((s) => _buildSummaryCard(s)),
                const SizedBox(height: 24),
                const Text(
                  'Recommendations',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...recommendations.map((r) => _buildRecommendationCard(r)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(dynamic summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Icon(Icons.analytics_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary['value'] ?? '',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic rec) {
    final type = rec['type'] ?? 'TIP';
    Color color = Colors.blue;
    IconData icon = Icons.lightbulb_outline;

    switch (type) {
      case 'WARNING':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
        break;
      case 'URGENT':
        color = Colors.red;
        icon = Icons.error_outline;
        break;
      case 'SUCCESS':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          type,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        subtitle: Text(
          rec['message'] ?? '',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
