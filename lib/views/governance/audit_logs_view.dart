import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../data/models/audit_log.dart';
import '../../viewmodels/governance_viewmodel.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernanceViewModel>().fetchAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchAuditLogs,
        child: viewModel.isLoading && viewModel.auditLogs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : viewModel.auditLogs.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 56, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No audit logs found.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: viewModel.auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = viewModel.auditLogs[index];
                      return _AuditLogCard(log: log);
                    },
                  ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.log});

  final AuditLogModel log;

  IconData get _icon {
    switch (log.action) {
      case 'CONTRIBUTION_ADD':
        return Icons.savings_outlined;
      case 'PENALTY_ISSUE':
        return Icons.gavel_outlined;
      case 'APPROVAL':
        return Icons.check_circle_outline;
      case 'ACTIVATION':
        return Icons.verified_outlined;
      case 'DEACTIVATION':
        return Icons.cancel_outlined;
      case 'MEMBERSHIP_CHANGE':
        return Icons.group_outlined;
      case 'ROLE_CHANGE':
        return Icons.manage_accounts_outlined;
      case 'LOGIN':
        return Icons.login_outlined;
      case 'PASSWORD_RESET':
        return Icons.lock_reset_outlined;
      case 'FINANCE_CHANGE':
        return Icons.edit_note_outlined;
      case 'FINANCE_ARCHIVE':
        return Icons.archive_outlined;
      default:
        return Icons.history;
    }
  }

  Color get _iconColor {
    switch (log.action) {
      case 'PENALTY_ISSUE':
      case 'DEACTIVATION':
      case 'FINANCE_ARCHIVE':
        return Colors.red.shade700;
      case 'APPROVAL':
      case 'ACTIVATION':
      case 'CONTRIBUTION_ADD':
        return Colors.green.shade700;
      case 'MEMBERSHIP_CHANGE':
      case 'ROLE_CHANGE':
        return Colors.blue.shade700;
      case 'FINANCE_CHANGE':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM dd, yyyy  HH:mm');
    final hasTarget = log.targetName.isNotEmpty &&
        log.targetName != 'Deleted User' &&
        log.targetName != log.actorName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon badge ───────────────────────────────────────────────
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Content ─────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action title
                  Text(
                    log.displayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Who performed the action
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'By',
                    value: log.actorName,
                    subtitle: log.actorRole.isNotEmpty
                        ? _formatRole(log.actorRole)
                        : null,
                  ),

                  // Who was affected
                  if (hasTarget) ...[
                    const SizedBox(height: 3),
                    _InfoRow(
                      icon: Icons.person_pin_outlined,
                      label: 'Affected',
                      value: log.targetName,
                      subtitle: log.targetEmail != log.targetName
                          ? log.targetEmail
                          : null,
                    ),
                  ],

                  // Notes / description
                  if (log.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.shade200, width: 0.8),
                      ),
                      child: Text(
                        log.notes,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],

                  // Timestamp
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        formatter.format(log.timestamp.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Administrator';
      case 'TREASURER':
        return 'Treasurer';
      case 'FINANCIAL_SECRETARY':
        return 'Financial Secretary';
      case 'MEMBER':
        return 'Member';
      default:
        return role.replaceAll('_', ' ');
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
