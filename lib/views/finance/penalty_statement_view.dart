import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../data/models/penalty.dart';

class PenaltyStatementView extends StatelessWidget {
  const PenaltyStatementView({super.key, required this.penalty});

  final Penalty penalty;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final isPaid = penalty.status == 'PAID';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penalty Statement'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Status hero banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPaid
                      ? [
                          const Color(0xFF2E7D32),
                          const Color(0xFF43A047),
                        ]
                      : [
                          const Color(0xFFB71C1C),
                          const Color(0xFFE53935),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isPaid ? Colors.green : Colors.red)
                        .withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isPaid ? Icons.verified_rounded : Icons.gavel_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currencyFormat.format(penalty.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      penalty.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Detail card ─────────────────────────────────────────────────
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.description_outlined,
                  label: 'Reason',
                  value: penalty.reason.isNotEmpty
                      ? penalty.reason
                      : 'No reason provided',
                  valueBold: true,
                ),
                const _Divider(),
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Date Issued',
                  value: dateFormat.format(penalty.date),
                ),
                const _Divider(),
                _DetailRow(
                  icon: Icons.group_outlined,
                  label: 'Group',
                  value: penalty.groupName ?? '—',
                ),
                const _Divider(),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Issued Against',
                  value: penalty.userName ?? 'You',
                ),
                if (penalty.appliedById != null) ...[
                  const _Divider(),
                  _DetailRow(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Issued By (ID)',
                    value: '#${penalty.appliedById}',
                  ),
                ],
                const _Divider(),
                _DetailRow(
                  icon: Icons.tag_outlined,
                  label: 'Penalty ID',
                  value: '#${penalty.id}',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Payment status notice ────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isPaid
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPaid
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.warning.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPaid
                        ? Icons.check_circle_outline
                        : Icons.access_time_outlined,
                    color: isPaid ? AppColors.success : AppColors.warning,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPaid
                          ? 'This penalty has been settled. No further action required.'
                          : 'This penalty is outstanding. Please contact your group treasurer to resolve it.',
                      style: TextStyle(
                        color: isPaid
                            ? AppColors.success
                            : const Color(0xFF7A4F00),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueBold = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        valueBold ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 50);
  }
}
