import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../data/models/investment.dart';
import '../widgets/custom_card.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class InvestmentDetailsView extends StatefulWidget {
  final Investment investment;

  const InvestmentDetailsView({super.key, required this.investment});

  @override
  State<InvestmentDetailsView> createState() => _InvestmentDetailsViewState();
}

class _InvestmentDetailsViewState extends State<InvestmentDetailsView> {
  bool _isApproving = false;
  bool _isRejecting = false;

  void _approveInvestment() async {
    setState(() => _isApproving = true);
    final viewModel = context.read<GovernanceViewModel>();
    final success = await viewModel.approveInvestment(widget.investment.id,
        notes: 'Approved via app');

    if (!mounted) return;
    setState(() => _isApproving = false);

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Investment Approved!'),
          backgroundColor: Colors.green));
      Navigator.pop(context); // Go back to refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to approve'), backgroundColor: Colors.red));
    }
  }

  void _rejectInvestment() async {
    final viewModel = context.read<GovernanceViewModel>();
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Investment'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
              hintText: 'Reason for rejection', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isEmpty) return;
              Navigator.pop(context, noteController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (note != null && note.isNotEmpty) {
      if (!mounted) return;
      setState(() => _isRejecting = true);

      final success =
          await viewModel.rejectInvestment(widget.investment.id, note);

      if (!mounted) return;
      setState(() => _isRejecting = false);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Investment Rejected!'),
            backgroundColor: Colors.orange));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to reject'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final investment = widget.investment;
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final dateFormat = DateFormat('MMMM dd, yyyy');

    final userViewModel = context.watch<UserViewModel>();
    final canApprove = (userViewModel.isAdmin || userViewModel.isTreasurer) &&
        investment.status == 'PENDING_APPROVAL';

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investment.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (investment.groupName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  investment.groupName!,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Started on ${dateFormat.format(investment.startDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            if (investment.createdByEmail != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Created by ${investment.createdByEmail}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (investment.financialCycleName != null &&
                investment.financialCycleName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.event_repeat, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Cycle: ${investment.financialCycleName}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            CustomCard(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DetailStat(
                    label: 'Total Invested',
                    value: currencyFormat.format(investment.amountInvested),
                    color: Colors.white,
                  ),
                  _DetailStat(
                    label: 'Expected ROI',
                    value: '${investment.expectedRoiPercentage}%',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                children: [
                  _PerformanceRow(
                      label: 'Description',
                      value: investment.description.isEmpty
                          ? 'N/A'
                          : investment.description),
                  const Divider(),
                  _PerformanceRow(
                      label: 'Category',
                      value: investment.category.isEmpty
                          ? 'N/A'
                          : investment.category),
                  const Divider(),
                  _PerformanceRow(
                      label: 'Purpose',
                      value: investment.purpose.isEmpty
                          ? 'N/A'
                          : investment.purpose),
                  if (investment.businessCase != null &&
                      investment.businessCase!.isNotEmpty) ...[
                    const Divider(),
                    _PerformanceRow(
                        label: 'Business Case',
                        value: investment.businessCase!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Performance & Rules',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                  _PerformanceRow(
                      label: 'Status',
                      value: investment.status,
                      isStatus: true),
                  if ((investment.decisionNotes ?? '').trim().isNotEmpty) ...[
                    const Divider(),
                    _PerformanceRow(
                      label: investment.status == 'REJECTED'
                          ? 'Rejection Reason'
                          : 'Decision Notes',
                      value: investment.decisionNotes!,
                    ),
                  ],
                  if (investment.reviewedByEmail != null &&
                      investment.reviewedByEmail!.isNotEmpty) ...[
                    const Divider(),
                    _PerformanceRow(
                        label: 'Reviewed By', value: investment.reviewedByEmail!),
                  ],
                  if (investment.reviewedAt != null) ...[
                    const Divider(),
                    _PerformanceRow(
                      label: 'Reviewed At',
                      value: dateFormat.format(investment.reviewedAt!),
                    ),
                  ],
                  const Divider(),
                  _PerformanceRow(
                      label: 'Return Type', value: investment.returnType),
                  const Divider(),
                  _PerformanceRow(
                      label: 'Payout Freq', value: investment.payoutFrequency),
                  const Divider(),
                  _PerformanceRow(
                      label: 'Risk Level', value: investment.riskLevel),
                  if (investment.duration != null) ...[
                    const Divider(),
                    _PerformanceRow(
                        label: 'Duration (Months)',
                        value: investment.duration.toString()),
                  ],
                  if (investment.minCapital != null) ...[
                    const Divider(),
                    _PerformanceRow(
                        label: 'Min Capital',
                        value: currencyFormat.format(investment.minCapital)),
                  ],
                  if (investment.lockInPeriod != null) ...[
                    const Divider(),
                    _PerformanceRow(
                        label: 'Lock-in (Months)',
                        value: investment.lockInPeriod.toString()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: canApprove ? _buildApprovalActions() : null,
    );
  }

  Widget _buildApprovalActions() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              onPressed:
                  (_isApproving || _isRejecting) ? null : _rejectInvestment,
              icon: _isRejecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.close, color: Colors.red),
              label: const Text('Reject', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
            ElevatedButton.icon(
              onPressed:
                  (_isApproving || _isRejecting) ? null : _approveInvestment,
              icon: _isApproving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            )
          ],
        ));
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _PerformanceRow(
      {required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isStatus
                    ? ((value == 'ACTIVE' || value == 'APPROVED')
                        ? Colors.green
                        : (value == 'PENDING_APPROVAL'
                            ? Colors.orange
                            : Colors.red))
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
