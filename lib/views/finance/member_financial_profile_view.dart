import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../../data/models/member_financial_profile.dart';
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
  final NumberFormat _currency = NumberFormat.currency(symbol: 'KES ');

  MemberFinancialProfile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<int?> _resolveMemberId() async {
    if (widget.memberId != null) return widget.memberId;

    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs is int) return routeArgs;
    if (routeArgs is Map) {
      final value = routeArgs['memberId'] ?? routeArgs['userId'];
      if (value is int) return value;
    }

    final currentUser = context.read<UserViewModel>().currentUser;
    if (currentUser != null) return currentUser.id;

    await context.read<UserViewModel>().fetchProfile();
    if (!mounted) return null;
    return context.read<UserViewModel>().currentUser?.id;
  }

  Future<void> _loadProfile() async {
    final memberId = await _resolveMemberId();
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
      final rawData = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};
      setState(() => _profile = MemberFinancialProfile.fromJson(rawData));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load the financial profile.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadStatement() async {
    final memberId = await _resolveMemberId();
    if (!mounted || memberId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDownloading = true);

    try {
      // Fetch memberships to get groupId
      final memResp = await _apiService.getMemberships();
      final data = memResp.data;
      final List memberships = data is List
          ? data
          : (data is Map && data['results'] is List
              ? data['results'] as List
              : []);
      if (memberships.isEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text('No group membership found for statement.')));
        return;
      }

      int? groupId;
      for (final item in memberships) {
        if (item is Map) {
          final groupVal = item['group'];
          if (groupVal is int) {
            groupId = groupVal;
            break;
          } else if (groupVal is Map && groupVal['id'] is int) {
            groupId = groupVal['id'] as int;
            break;
          }
        }
      }

      if (groupId == null) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Could not determine group for statement.')));
        return;
      }

      await _apiService.downloadMemberStatementPdf(
        groupId: groupId,
        memberId: memberId,
      );

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Statement downloaded successfully.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content:
              Text('Unable to download statement. Please try again later.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<UserViewModel>().currentUser?.id;
    final isOwnProfile = widget.memberId == null || widget.memberId == currentUserId;
    final title = isOwnProfile
        ? 'My Financial Profile'
        : (_profile != null ? '${_profile!.member.name}\'s Profile' : 'Financial Profile');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _error == null)
            _isDownloading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    tooltip: 'Download Statement PDF',
                    icon: const Icon(Icons.download_outlined),
                    onPressed: _downloadStatement,
                  ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadProfile)
              : _profile == null
                  ? _ErrorView(
                      message: 'No financial profile data found.',
                      onRetry: _loadProfile,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProfile,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // ── Hero header ──────────────────────────────────
                            _ProfileHero(member: _profile!.member),

                            // ── Metric cards ─────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: GridView.count(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 1.45,
                                children: [
                                  _MetricCard(
                                    label: 'Total Savings',
                                    value: _currency
                                        .format(_profile!.totalSavings),
                                    icon: Icons.savings_outlined,
                                    gradient: const [
                                      Color(0xFF1B5E20),
                                      Color(0xFF43A047)
                                    ],
                                  ),
                                  _MetricCard(
                                    label: 'Penalties',
                                    value: _currency
                                        .format(_profile!.totalPenalties),
                                    icon: Icons.gavel_outlined,
                                    gradient: const [
                                      Color(0xFFB71C1C),
                                      Color(0xFFE57373)
                                    ],
                                  ),
                                  _MetricCard(
                                    label: 'Investments',
                                    value: _currency
                                        .format(_profile!.totalInvestments),
                                    icon: Icons.trending_up,
                                    gradient: const [
                                      Color(0xFF0D47A1),
                                      Color(0xFF42A5F5)
                                    ],
                                  ),
                                  _MetricCard(
                                    label: 'Outstanding',
                                    value: _currency
                                        .format(_profile!.outstandingBalance),
                                    icon: Icons.account_balance_outlined,
                                    gradient: const [
                                      Color(0xFF7B1FA2),
                                      Color(0xFFBA68C8)
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ── Detail rows ──────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: _DetailSection(
                                children: [
                                  _DetailRow(
                                    label: 'Total contributions',
                                    value: _currency.format(
                                        _profile!.totalContributions),
                                  ),
                                  _DetailRow(
                                    label: 'Verified repayments',
                                    value: _currency
                                        .format(_profile!.totalRepayments),
                                  ),
                                  _DetailRow(
                                    label: 'Active loans',
                                    value: '${_profile!.activeLoans}',
                                  ),
                                  _DetailRow(
                                    label: 'Overdue loans',
                                    value: '${_profile!.overdueLoans}',
                                  ),
                                  _DetailRow(
                                    label: 'Overdue balance',
                                    value: _currency
                                        .format(_profile!.overdueBalance),
                                  ),
                                  _DetailRow(
                                    label: 'Net position',
                                    value: _currency
                                        .format(_profile!.netPosition),
                                    isHighlighted: true,
                                  ),
                                ],
                              ),
                            ),

                            // ── Action buttons ───────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 32),
                              child: Column(
                                children: [
                                  // View full financial history
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.history),
                                      label: const Text(
                                          'View Full Financial History'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(
                                            color: AppColors.primary,
                                            width: 1.5),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final memberId =
                                            await _resolveMemberId();
                                        if (!context.mounted) return;
                                        Navigator.pushNamed(
                                          context,
                                          '/finance/history',
                                          arguments: memberId,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // View My Loans
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.account_balance),
                                      label: Text(isOwnProfile
                                          ? 'View My Loans'
                                          : 'View Loans'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF00695C),
                                        side: const BorderSide(
                                            color: Color(0xFF00695C),
                                            width: 1.5),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pushNamed(
                                          context, '/finance/loans'),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // View Penalties
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.gavel_outlined),
                                      label: Text(isOwnProfile
                                          ? 'View My Penalties'
                                          : 'View Penalties'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        side: BorderSide(
                                            color: AppColors.error
                                                .withValues(alpha: 0.7),
                                            width: 1.5),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pushNamed(
                                          context, '/penalties'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

// ── Hero header ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.member});

  final MemberProfileInfo member;

  @override
  Widget build(BuildContext context) {
    final name = member.name.isNotEmpty ? member.name : 'Member';
    final membershipNumber = member.membershipNumber;
    final email = member.email;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary, Color(0xFF1E3A5F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 2.5),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (membershipNumber != null && membershipNumber.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                membershipNumber,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Gradient metric card ─────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Detail section + rows ─────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isHighlighted
                      ? AppColors.textPrimary
                      : Colors.grey[700],
                  fontWeight:
                      isHighlighted ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight:
                      isHighlighted ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isHighlighted ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

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
          Icon(Icons.error_outline, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
