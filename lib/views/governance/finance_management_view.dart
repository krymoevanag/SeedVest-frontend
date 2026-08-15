import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../data/models/contribution.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../data/models/membership.dart';
import '../widgets/custom_card.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/user_viewmodel.dart';
import 'group_settings_view.dart';

class FinanceManagementView extends StatefulWidget {
  const FinanceManagementView({super.key});

  @override
  State<FinanceManagementView> createState() => _FinanceManagementViewState();
}

class _FinanceManagementViewState extends State<FinanceManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'KSH ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financeVm = context.read<FinanceViewModel>();
      final governanceVm = context.read<GovernanceViewModel>();

      governanceVm.fetchGroups().then((groups) {
        if (groups.isNotEmpty && financeVm.selectedGroupId == null) {
          financeVm.setSelectedGroup(groups.first['id']);
        } else {
          financeVm.fetchAdminMemberships();
          if (financeVm.selectedGroupId != null) {
            financeVm.fetchAdminGroupSummary();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Financial Oversight'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final financeVm = context.read<FinanceViewModel>();
              financeVm.fetchAdminMemberships();
              financeVm.fetchAdminGroupSummary();
            },
          ),
        ],
      ),
      body: Consumer2<FinanceViewModel, GovernanceViewModel>(
        builder: (context, financeVm, governanceVm, child) {
          if (governanceVm.isLoading && governanceVm.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (governanceVm.groups.isEmpty) {
            return const Center(child: Text("No groups found."));
          }

          return Column(
            children: [
              _buildHeader(financeVm, governanceVm),
              _buildSearchBar(financeVm),
              Expanded(
                child: financeVm.isLoading && financeVm.adminMemberships.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMemberTable(financeVm),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      FinanceViewModel financeVm, GovernanceViewModel governanceVm) {
    final summary = financeVm.adminGroupSummary;
    final stats = summary?['stats'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Context",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<int>(
                      value: financeVm.selectedGroupId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: governanceVm.groups.map((g) {
                        return DropdownMenuItem<int>(
                          value: g['id'],
                          child: Text(
                            g['name'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        financeVm.setSelectedGroup(value);
                      },
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: AppColors.primary),
                onPressed: () {
                  final group = governanceVm.groups.firstWhere(
                    (g) => g['id'] == financeVm.selectedGroupId,
                    orElse: () => null,
                  );
                  if (group != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupSettingsView(group: group),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildCompactStat(
                "Members",
                "${stats?['member_count'] ?? '0'}",
                Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  "Total Savings",
                  _currencyFormat.format(double.tryParse(
                          stats?['total_savings']?.toString() ?? '0') ??
                      0),
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  "Unpaid Penalties",
                  _currencyFormat.format(double.tryParse(
                          stats?['total_penalties']?.toString() ?? '0') ??
                      0),
                  Icons.gavel_rounded,
                  AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (context.read<UserViewModel>().isTreasurer)
            _buildAdminActions(context, financeVm),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, FinanceViewModel financeVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Admin Actions",
          style: TextStyle(
              fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: financeVm.isLoading
                    ? null
                    : () =>
                        _confirmProcessAutoSave(context, financeVm, 'generate'),
                icon: const Icon(Icons.autorenew),
                label: const Text("Process Generations"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: financeVm.isLoading
                    ? null
                    : () =>
                        _confirmProcessAutoSave(context, financeVm, 'enforce'),
                icon: const Icon(Icons.gavel_rounded),
                label: const Text("Enforce Penalties"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmProcessAutoSave(
      BuildContext context, FinanceViewModel financeVm, String action) {
    final isEnforce = action == 'enforce';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnforce ? "Enforce Compliance" : "Process Generations"),
        content: Text(
          isEnforce
              ? "This will check for savings compliance across all members. "
                  "Non-compliant members (below minimum) will be issued penalties and receive email notifications.\n\nDo you want to proceed?"
              : "This will generate PENDING contribution records for all members with active auto-saving configurations for the current month. "
                  "Members will receive notifications.\n\nDo you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final success = await financeVm.triggerAutoSave(action: action);
              if (mounted) {
                if (success) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            "${isEnforce ? 'Penalties' : 'Auto-savings'} processed successfully")),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            "Failed to process ${isEnforce ? 'penalties' : 'auto-savings'}"),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isEnforce ? "Enforce Now" : "Process Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(FinanceViewModel financeVm) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or MBR number...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          financeVm.fetchAdminMemberships(search: value);
        },
      ),
    );
  }

  Widget _buildMemberTable(FinanceViewModel financeVm) {
    if (financeVm.adminMemberships.isEmpty) {
      return const Center(child: Text("No members found in this scope."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: financeVm.adminMemberships.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final membership = Membership.fromJson(
          Map<String, dynamic>.from(financeVm.adminMemberships[index]),
        );
        return _buildMemberCard(membership);
      },
    );
  }

  Widget _buildMemberCard(Membership m) {
    final lastContributionLabel = m.lastContributionDate == null
        ? 'No contributions recorded'
        : 'Last contribution: ${DateFormat('dd MMM yyyy').format(m.lastContributionDate!)}';

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.fullName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      m.membershipNumber ?? "No MBR#",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _buildTrailingAction(m),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMiniBalance(
                    "Savings", m.savingsBalance, AppColors.primary),
              ),
              Expanded(
                child: _buildMiniBalance(
                    "Penalties", m.penaltiesBalance, AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMiniBalance(
                  "Expected",
                  m.expectedTotal,
                  Colors.blueGrey,
                ),
              ),
              Expanded(
                child: _buildMiniBalance(
                  "Outstanding",
                  m.outstandingTotal,
                  m.outstandingTotal > 0 ? AppColors.warning : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(
                'Total ${m.totalContributionsCount}',
                Colors.blueGrey,
              ),
              _buildStatusChip(
                'Paid ${m.paidContributionsCount}',
                Colors.green,
              ),
              _buildStatusChip(
                'Pending ${m.pendingContributionsCount}',
                Colors.orange,
              ),
              _buildStatusChip(
                'Overdue ${m.overdueContributionsCount}',
                AppColors.error,
              ),
              _buildStatusChip(
                'Rejected ${m.rejectedContributionsCount}',
                Colors.brown,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lastContributionLabel,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'Amount: ${_currencyFormat.format(m.lastContributionAmount)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showContributionBreakdown(m),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('View contribution records'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBalance(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTrailingAction(Membership m) {
    if (!context.read<UserViewModel>().isTreasurer) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      onSelected: (value) {
        if (value == 'contribution') {
          _showContributionDialog(m);
        } else if (value == 'penalty') {
          _showPenaltyDialog(m);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'contribution',
          child: Row(
            children: [
              Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text("Add Contribution"),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'penalty',
          child: Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text("Issue Penalty"),
            ],
          ),
        ),
      ],
    );
  }

  void _showContributionBreakdown(Membership membership) {
    final cycleId = context.read<FinanceViewModel>().selectedCycleId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: _ContributionBreakdownSheet(
          membership: membership,
          cycleId: cycleId,
        ),
      ),
    );
  }

  void _showContributionDialog(Membership m) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Contribution - ${m.fullName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (KSH)",
                prefixText: "KSH ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final success =
                  await context.read<FinanceViewModel>().adminAddContribution({
                'user_id': m.userId,
                'group_id': m.groupId,
                'amount': amount,
              });

              if (success && mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text("Contribution added successfully")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showPenaltyDialog(Membership m) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Issue Penalty - ${m.fullName}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (KSH)",
                prefixText: "KSH ",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason",
                hintText: "e.g., Late meeting attendance",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              if (reasonController.text.isEmpty) return;

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final success =
                  await context.read<FinanceViewModel>().adminIssuePenalty({
                'user': m.userId,
                'amount': amount,
                'reason': reasonController.text,
              });

              if (success && mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Penalty issued successfully")),
                );
              }
            },
            child: const Text("Issue"),
          ),
        ],
      ),
    );
  }
}

class _ContributionBreakdownSheet extends StatefulWidget {
  final Membership membership;
  final int? cycleId;

  const _ContributionBreakdownSheet({
    required this.membership,
    required this.cycleId,
  });

  @override
  State<_ContributionBreakdownSheet> createState() =>
      _ContributionBreakdownSheetState();
}

class _ContributionBreakdownSheetState
    extends State<_ContributionBreakdownSheet> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'KSH ');
  bool _isLoading = true;
  String? _error;
  List<Contribution> _contributions = [];
  String _statusFilter = 'ALL';
  String _sortOption = 'Newest first';

  static const List<String> _statusOptions = [
    'ALL',
    'PAID',
    'LATE',
    'PENDING',
    'OVERDUE',
    'REJECTED',
  ];

  static const List<String> _sortOptions = [
    'Newest first',
    'Oldest first',
    'Amount high-low',
    'Amount low-high',
    'Status',
  ];

  @override
  void initState() {
    super.initState();
    _loadContributions();
  }

  Future<void> _loadContributions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items =
          await context.read<FinanceViewModel>().getMemberContributionBreakdown(
                userId: widget.membership.userId,
                groupId: widget.membership.groupId,
                cycleId: widget.cycleId,
              );
      if (!mounted) {
        return;
      }
      setState(() {
        _contributions = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load contribution records.';
        _isLoading = false;
      });
    }
  }

  List<Contribution> get _visibleContributions {
    final filtered = _contributions.where((contribution) {
      if (_statusFilter == 'ALL') {
        return true;
      }
      return contribution.status == _statusFilter;
    }).toList();

    switch (_sortOption) {
      case 'Oldest first':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Amount high-low':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Amount low-high':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'Status':
        filtered.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'Newest first':
      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
        return Colors.green;
      case 'LATE':
        return Colors.deepOrange;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
        return AppColors.error;
      case 'REJECTED':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBalance = _contributions
        .where((item) => item.status == 'PAID' || item.status == 'LATE')
        .fold<double>(0, (total, item) => total + item.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            widget.membership.fullName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.membership.groupName} • ${widget.membership.membershipNumber ?? "No membership number"}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _BreakdownStat(
                    label: 'Active balance',
                    value: _currencyFormat.format(activeBalance),
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _BreakdownStat(
                    label: 'Transactions',
                    value: '${_contributions.length}',
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter',
                    border: OutlineInputBorder(),
                  ),
                  items: _statusOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option == 'ALL' ? 'All statuses' : option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _statusFilter = value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortOption,
                  decoration: const InputDecoration(
                    labelText: 'Sort',
                    border: OutlineInputBorder(),
                  ),
                  items: _sortOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _sortOption = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      )
                    : _visibleContributions.isEmpty
                        ? Center(
                            child: Text(
                              _contributions.isEmpty
                                  ? 'No contribution records found for this member.'
                                  : 'No records match the selected filter.',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadContributions,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _visibleContributions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final contribution =
                                    _visibleContributions[index];
                                final statusColor =
                                    _statusColor(contribution.status);

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _currencyFormat
                                                  .format(contribution.amount),
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              contribution.status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Captured: ${DateFormat('dd MMM yyyy, HH:mm').format(contribution.date.toLocal())}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Due date: ${contribution.dueDate == null ? "Not set" : DateFormat('dd MMM yyyy').format(contribution.dueDate!.toLocal())}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      Text(
                                        'Paid date: ${contribution.paidDate == null ? "Not paid" : DateFormat('dd MMM yyyy').format(contribution.paidDate!.toLocal())}',
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      if ((contribution.reportedPaymentMethod ?? '')
                                          .isNotEmpty)
                                        Text(
                                          'Method: ${contribution.reportedPaymentMethod}',
                                          style:
                                              TextStyle(color: Colors.grey[700]),
                                        ),
                                      if ((contribution.reportedReference ?? '')
                                          .isNotEmpty)
                                        Text(
                                          'Reference: ${contribution.reportedReference}',
                                          style:
                                              TextStyle(color: Colors.grey[700]),
                                        ),
                                      if ((contribution.reportedNote ?? '').isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            contribution.reportedNote!,
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                      if ((contribution.rejectionReason ?? '')
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Review note: ${contribution.rejectionReason}',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BreakdownStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
