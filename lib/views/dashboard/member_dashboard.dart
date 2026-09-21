import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/user_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_card.dart';
import '../widgets/contribution_bottom_sheet.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserViewModel>().currentUser;
      context.read<DashboardViewModel>().fetchDashboardData(userId: user?.id);
    });
  }

  Future<void> _refresh() async {
    final user = context.read<UserViewModel>().currentUser;
    await context.read<DashboardViewModel>().fetchDashboardData(userId: user?.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>().currentUser;
    final viewModel = context.watch<DashboardViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Greeting + Profile avatar) ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.fullName ?? 'Member',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: user?.profilePicture != null
                          ? NetworkImage(user!.profilePicture!)
                          : null,
                      child: user?.profilePicture == null
                          ? const Icon(Icons.person, color: AppColors.primary)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Personal Savings Card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, Color(0xFF1E3A5F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Total Savings',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.person,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'Personal',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(viewModel.totalSavings),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up,
                            color: Colors.green[300], size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Group Balance Card ───────────────────────────────────────
              if (viewModel.groupName != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${viewModel.groupName} Pool',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF37474F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currencyFormat.format(viewModel.groupBalance),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (viewModel.groupMemberCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${viewModel.groupMemberCount} members',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // ── Quick Action Cards (4 Actions) ───────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Contribute',
                      icon: Icons.add_circle_outline,
                      color: AppColors.primary,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) =>
                              const ContributionBottomSheet(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Loans',
                      icon: Icons.account_balance,
                      color: const Color(0xFF00695C),
                      onTap: () =>
                          Navigator.pushNamed(context, '/finance/loans'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Penalties',
                      icon: Icons.gavel_outlined,
                      color: AppColors.error,
                      onTap: () => Navigator.pushNamed(context, '/penalties'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickActionCard(
                      title: 'Profile',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF0D47A1),
                      onTap: () =>
                          Navigator.pushNamed(context, '/finance/profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Recent Activity Header ───────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/finance/history'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Multi-Type Recent Activity List ──────────────────────────
              if (viewModel.isLoading &&
                  viewModel.recentActivities.isEmpty &&
                  viewModel.recentContributions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (viewModel.recentActivities.isEmpty &&
                  viewModel.recentContributions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activity found.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
              else if (viewModel.recentActivities.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.recentActivities.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = viewModel.recentActivities[index];
                    return _ActivityTile(
                      activity: item,
                      currencyFormat: currencyFormat,
                      onTap: () =>
                          Navigator.pushNamed(context, '/finance/history'),
                    );
                  },
                )
              else
                // Fallback to recent contributions if activity history is empty
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewModel.recentContributions.take(5).length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final contrib = viewModel.recentContributions[index];
                    return _LegacyContributionTile(
                      contribution: contrib,
                      currencyFormat: currencyFormat,
                      onTap: () =>
                          Navigator.pushNamed(context, '/finance/history'),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Action Card Widget ────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity Tile Widget ────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.currencyFormat,
    required this.onTap,
  });

  final Map<String, dynamic> activity;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = activity['type']?.toString().toLowerCase() ?? 'contribution';
    final amount = double.tryParse(activity['amount']?.toString() ?? '0') ?? 0.0;
    final dateStr = activity['date']?.toString() ?? '';
    final description = activity['description']?.toString() ?? '';
    final status = activity['status']?.toString() ?? '';

    IconData icon;
    Color color;
    String sign;
    String typeLabel;

    switch (type) {
      case 'contribution':
        icon = Icons.arrow_upward;
        color = AppColors.primary;
        sign = '+';
        typeLabel = 'Contribution';
        break;
      case 'repayment':
        icon = Icons.payment;
        color = const Color(0xFF00695C);
        sign = '-';
        typeLabel = 'Loan Repay';
        break;
      case 'penalty':
        icon = Icons.gavel;
        color = AppColors.error;
        sign = '';
        typeLabel = 'Penalty';
        break;
      case 'investment':
        icon = Icons.trending_up;
        color = const Color(0xFF0D47A1);
        sign = '';
        typeLabel = 'Investment';
        break;
      default:
        icon = Icons.receipt_long;
        color = Colors.grey;
        sign = '';
        typeLabel = 'Transaction';
    }

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {}

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description.isNotEmpty ? description : typeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  parsedDate != null
                      ? DateFormat('MMM dd, yyyy').format(parsedDate)
                      : dateStr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${currencyFormat.format(amount)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: type == 'contribution'
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              if (status.isNotEmpty)
                Text(
                  status,
                  style: TextStyle(
                    color: status == 'PAID' || status == 'VERIFIED'
                        ? Colors.green[700]
                        : Colors.orange[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Legacy Contribution Tile Widget ─────────────────────────────────────────

class _LegacyContributionTile extends StatelessWidget {
  const _LegacyContributionTile({
    required this.contribution,
    required this.currencyFormat,
    required this.onTap,
  });

  final dynamic contribution;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_upward,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(contribution.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${currencyFormat.format(contribution.amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
              Text(
                contribution.status,
                style: TextStyle(
                  color: contribution.status == 'PAID'
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
