import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _readInt(
    Map<String, dynamic> stats,
    List<String> keys, {
    int fallback = 0,
  }) {
    for (final key in keys) {
      final value = stats[key];
      final parsed = _toInt(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  double _readDouble(
    Map<String, dynamic> stats,
    List<String> keys, {
    double fallback = 0,
  }) {
    for (final key in keys) {
      final value = stats[key];
      final parsed = _toDouble(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.replaceAll(',', '').trim();
      final intValue = int.tryParse(normalized);
      if (intValue != null) return intValue;
      final doubleValue = double.tryParse(normalized);
      if (doubleValue != null) return doubleValue.toInt();
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '').trim();
      return double.tryParse(normalized);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().fetchAdminStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final stats = viewModel.adminStats;
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final totalUsers = _readInt(
      stats,
      const ['total_users', 'all_members', 'members_count'],
    );
    final pendingApprovals = _readInt(
      stats,
      const ['pending_approvals', 'pending_members'],
    );
    final totalSavings = _readDouble(
      stats,
      const ['total_savings', 'total_contributions', 'savings_total'],
    );
    final totalPenalties = _readDouble(
      stats,
      const ['total_penalties', 'penalties_total'],
    );
    final grandTotal = _readDouble(
      stats,
      const ['grand_total', 'overall_total', 'group_total'],
      fallback: totalSavings + totalPenalties,
    );
    final pendingPayments = _readInt(
      stats,
      const [
        'pending_contributions_count',
        'pending_payments',
        'pending_contributions',
      ],
    );

    return RefreshIndicator(
      onRefresh: viewModel.fetchAdminStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Key Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  title: 'All Members',
                  value: totalUsers.toString(),
                  icon: Icons.people_outline,
                  color: Colors.blue,
                  onTap: () =>
                      Navigator.pushNamed(context, '/governance/roles'),
                ),
                _StatCard(
                  title: 'Pending Approvals',
                  value: pendingApprovals.toString(),
                  icon: Icons.how_to_reg,
                  color: Colors.orange,
                  onTap: () =>
                      Navigator.pushNamed(context, '/governance/approvals'),
                ),
                _StatCard(
                  title: 'Total Savings',
                  value: currencyFormat.format(totalSavings),
                  icon: Icons.savings_outlined,
                  color: Colors.green,
                  isCurrency: true,
                  onTap: () =>
                      Navigator.pushNamed(context, '/governance/contributions'),
                ),
                _StatCard(
                  title: 'Total Penalties',
                  value: currencyFormat.format(totalPenalties),
                  icon: Icons.gavel,
                  color: Colors.redAccent,
                  isCurrency: true,
                  onTap: () => Navigator.pushNamed(context, '/penalties'),
                ),
                _StatCard(
                  title: 'Grand Total',
                  value: currencyFormat.format(grandTotal),
                  icon: Icons.account_balance,
                  color: AppColors.primary,
                  isCurrency: true,
                ),
                _StatCard(
                  title: 'Pending Payments',
                  value: pendingPayments.toString(),
                  icon: Icons.pending_actions,
                  color: Colors.amber,
                  onTap: () =>
                      Navigator.pushNamed(context, '/governance/contributions'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1,
                        color: AppColors.primary),
                    title: const Text('Register New Member'),
                    subtitle: const Text('Manually add a member to the system'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(
                        context, '/governance/register-member'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person_search,
                        color: AppColors.primary),
                    title: const Text('Review New Members'),
                    subtitle:
                        const Text('Approve or reject pending applications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () =>
                        Navigator.pushNamed(context, '/governance/approvals'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.send_rounded,
                        color: AppColors.primary),
                    title: const Text('Send Broadcast'),
                    subtitle:
                        const Text('Send internal message to all members'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () =>
                        Navigator.pushNamed(context, '/governance/broadcast'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.attach_money,
                        color: AppColors.primary),
                    title: const Text('Manage Investments'),
                    subtitle:
                        const Text('Create or update investment portfolios'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () =>
                        Navigator.pushNamed(context, '/governance/finance'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.gavel, color: AppColors.accent),
                    title: const Text('Manage Penalties'),
                    subtitle: const Text('Review and apply penalties'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, '/penalties'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isCurrency;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isCurrency = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isCurrency ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
