import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../data/models/loan.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class LoansOverviewView extends StatefulWidget {
  const LoansOverviewView({super.key});

  @override
  State<LoansOverviewView> createState() => _LoansOverviewViewState();
}

class _LoansOverviewViewState extends State<LoansOverviewView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanViewModel>().initialise();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final currentUserId = userViewModel.currentUser?.id;
    final canManage = userViewModel.isAdmin || userViewModel.isTreasurer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            tooltip: 'Refresh loans',
            onPressed: () => context.read<LoanViewModel>().fetchLoans(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplicationDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Apply for loan'),
      ),
      body: Consumer<LoanViewModel>(
        builder: (context, loansViewModel, _) {
          if (loansViewModel.isLoading && loansViewModel.loans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (loansViewModel.error != null && loansViewModel.loans.isEmpty) {
            return _ErrorState(
              message: loansViewModel.error!,
              onRetry: loansViewModel.fetchLoans,
            );
          }
          if (loansViewModel.loans.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: loansViewModel.fetchLoans,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (loansViewModel.error != null)
                  _MessageBanner(message: loansViewModel.error!),
                ...loansViewModel.loans.map(
                  (loan) => _LoanCard(
                    loan: loan,
                    currentUserId: currentUserId,
                    canManage: canManage,
                    onAcceptGuarantee: () => _respondToGuarantee(loan, true),
                    onRejectGuarantee: () => _respondToGuarantee(loan, false),
                    onApprove: () => _performAction(
                      title: 'Approve loan',
                      prompt: 'Approve this loan application?',
                      action: () => loansViewModel.approveLoan(loan.id),
                    ),
                    onReject: () => _performReasonAction(
                      title: 'Reject loan',
                      prompt: 'Why is this loan application being rejected?',
                      action: (reason) =>
                          loansViewModel.rejectLoan(loan.id, reason),
                    ),
                    onDisburse: () => _performAction(
                      title: 'Disburse loan',
                      prompt: 'Record this loan as disbursed?',
                      action: () => loansViewModel.disburseLoan(loan.id),
                    ),
                    onRepay: () => _showRepaymentDialog(loan),
                    onVerifyRepayment: (repayment) => _performAction(
                      title: 'Verify repayment',
                      prompt:
                          'Verify KES ${_money(repayment.amount)} from ${repayment.userName}?',
                      action: () =>
                          loansViewModel.verifyRepayment(loan.id, repayment.id),
                    ),
                    onRejectRepayment: (repayment) => _performReasonAction(
                      title: 'Reject repayment',
                      prompt: 'Why is this repayment being rejected?',
                      action: (reason) => loansViewModel.rejectRepayment(
                          loan.id, repayment.id, reason),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showApplicationDialog() async {
    final loanViewModel = context.read<LoanViewModel>();
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    var selectedGroupId = loanViewModel.groups.isNotEmpty
        ? _asInt(loanViewModel.groups.first['id'])
        : null;
    var interestRate = 5.0;
    var durationMonths = 1;
    var amount = 0.0;
    final guarantorIds = <int>{};

    if (selectedGroupId != null) {
      await loanViewModel.fetchEligibleGuarantors(selectedGroupId);
    }
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final calculatedTotal = loanViewModel.calculateTotalPayable(
            amount: amount,
            interestRate: interestRate,
            durationMonths: durationMonths,
          );
          return AlertDialog(
            title: const Text('Loan application'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: selectedGroupId,
                        decoration: const InputDecoration(labelText: 'Group'),
                        items: loanViewModel.groups
                            .map(
                              (group) => DropdownMenuItem<int>(
                                value: _asInt(group['id']),
                                child:
                                    Text(group['name']?.toString() ?? 'Group'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) async {
                          setDialogState(() {
                            selectedGroupId = value;
                            guarantorIds.clear();
                          });
                          if (value != null) {
                            await loanViewModel.fetchEligibleGuarantors(value);
                            if (mounted) setDialogState(() {});
                          }
                        },
                        validator: (value) =>
                            value == null ? 'Select a group.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Requested amount (KES)',
                          prefixText: 'KES ',
                        ),
                        onChanged: (value) {
                          setDialogState(
                              () => amount = double.tryParse(value) ?? 0);
                        },
                        validator: (value) {
                          if ((double.tryParse(value ?? '') ?? 0) <= 0) {
                            return 'Enter a valid amount.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                          'Interest per month: ${interestRate.toStringAsFixed(1)}%'),
                      Slider(
                        min: 5,
                        max: 10,
                        divisions: 10,
                        label: '${interestRate.toStringAsFixed(1)}%',
                        value: interestRate,
                        onChanged: (value) =>
                            setDialogState(() => interestRate = value),
                      ),
                      Text(
                          'Repayment duration: $durationMonths month${durationMonths == 1 ? '' : 's'}'),
                      Slider(
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$durationMonths months',
                        value: durationMonths.toDouble(),
                        onChanged: (value) => setDialogState(
                            () => durationMonths = value.round()),
                      ),
                      Card(
                        color: AppColors.background,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Simple-interest estimate',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  'Total payable: KES ${_money(calculatedTotal)}'),
                              Text(
                                  'Interest: KES ${_money(calculatedTotal - amount)}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: purposeController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Purpose (optional)'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select at least two active group members as guarantors',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (loanViewModel.eligibleGuarantors.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                              'No eligible guarantors found for this group.'),
                        )
                      else
                        ...loanViewModel.eligibleGuarantors.map((guarantor) {
                          final id = _asInt(guarantor['id']);
                          if (id == null) return const SizedBox.shrink();
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: guarantorIds.contains(id),
                            title:
                                Text(guarantor['full_name']?.toString() ?? ''),
                            subtitle:
                                Text(guarantor['email']?.toString() ?? ''),
                            onChanged: (selected) {
                              setDialogState(() {
                                if (selected == true) {
                                  guarantorIds.add(id);
                                } else {
                                  guarantorIds.remove(id);
                                }
                              });
                            },
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: loanViewModel.isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: loanViewModel.isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        if (guarantorIds.length < 2) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Select at least two guarantors.')),
                          );
                          return;
                        }
                        final success = await loanViewModel.applyLoan(
                          groupId: selectedGroupId!,
                          amount: amount,
                          interestRate: interestRate,
                          durationMonths: durationMonths,
                          purpose: purposeController.text,
                          guarantorUserIds: guarantorIds.toList(),
                        );
                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pop(dialogContext);
                          _showMessage('Loan application submitted.',
                              success: true);
                        } else {
                          _showMessage(loanViewModel.error ??
                              'Loan application failed.');
                        }
                      },
                child: loanViewModel.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit application'),
              ),
            ],
          );
        },
      ),
    );
    amountController.dispose();
    purposeController.dispose();
  }

  Future<void> _respondToGuarantee(Loan loan, bool accepted) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(accepted ? 'Accept guarantee' : 'Reject guarantee'),
        content: TextField(
          controller: notesController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(accepted ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final loanViewModel = context.read<LoanViewModel>();
    final success = await loanViewModel.respondToGuarantee(
      loan.id,
      accepted,
      notes: notesController.text,
    );
    notesController.dispose();
    if (!context.mounted) return;
    _showMessage(
      success
          ? 'Guarantee response recorded.'
          : (loanViewModel.error ?? 'Request failed.'),
      success: success,
    );
  }

  Future<void> _showRepaymentDialog(Loan loan) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    var paymentMethod = 'MPESA';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Submit repayment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Remaining balance: KES ${_money(loan.balanceRemaining)}'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Amount (KES)'),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '') ?? 0;
                      if (amount <= 0 || amount > loan.balanceRemaining) {
                        return 'Enter an amount up to the remaining balance.';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration:
                        const InputDecoration(labelText: 'Payment method'),
                    items: const [
                      DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                      DropdownMenuItem(
                          value: 'BANK_TRANSFER', child: Text('Bank transfer')),
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => paymentMethod = value!),
                  ),
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                        labelText: 'Transaction reference'),
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration:
                        const InputDecoration(labelText: 'Note (optional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final loanViewModel = context.read<LoanViewModel>();
                final success = await loanViewModel.submitRepayment(
                  loanId: loan.id,
                  amount: double.parse(amountController.text),
                  paymentMethod: paymentMethod,
                  transactionReference: referenceController.text,
                  notes: notesController.text,
                );
                if (!context.mounted) return;
                if (success) {
                  Navigator.pop(dialogContext);
                }
                _showMessage(
                  success
                      ? 'Repayment submitted for verification.'
                      : (loanViewModel.error ?? 'Repayment failed.'),
                  success: success,
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    referenceController.dispose();
    notesController.dispose();
  }

  Future<void> _performAction({
    required String title,
    required String prompt,
    required Future<bool> Function() action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(prompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final loanViewModel = context.read<LoanViewModel>();
    final success = await action();
    if (!context.mounted) return;
    _showMessage(
      success ? '$title completed.' : (loanViewModel.error ?? '$title failed.'),
      success: success,
    );
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _performReasonAction({
    required String title,
    required String prompt,
    required Future<bool> Function(String reason) action,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(labelText: prompt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      reasonController.dispose();
      return;
    }
    final loanViewModel = context.read<LoanViewModel>();
    final success = await action(reasonController.text.trim());
    reasonController.dispose();
    if (!mounted) return;
    _showMessage(
      success ? '$title completed.' : (loanViewModel.error ?? '$title failed.'),
      success: success,
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({
    required this.loan,
    required this.currentUserId,
    required this.canManage,
    required this.onAcceptGuarantee,
    required this.onRejectGuarantee,
    required this.onApprove,
    required this.onReject,
    required this.onDisburse,
    required this.onRepay,
    required this.onVerifyRepayment,
    required this.onRejectRepayment,
  });

  final Loan loan;
  final int? currentUserId;
  final bool canManage;
  final VoidCallback onAcceptGuarantee;
  final VoidCallback onRejectGuarantee;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDisburse;
  final VoidCallback onRepay;
  final ValueChanged<LoanRepayment> onVerifyRepayment;
  final ValueChanged<LoanRepayment> onRejectRepayment;

  @override
  Widget build(BuildContext context) {
    final isBorrower = currentUserId == loan.userId;
    final isPendingGuarantor = currentUserId != null &&
        loan.isGuarantor(currentUserId!) &&
        loan.status == 'PENDING_GUARANTORS';
    final pendingRepayments = loan.repayments
        .where((repayment) => repayment.status == 'PENDING')
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.groupName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StatusBadge(status: loan.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('Borrower: ${loan.borrowerName}'),
            if (loan.purpose.isNotEmpty) Text('Purpose: ${loan.purpose}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _Metric(
                    label: 'Principal', value: 'KES ${_money(loan.amount)}'),
                _Metric(
                    label: 'Interest',
                    value: '${loan.interestRate.toStringAsFixed(1)}% / month'),
                _Metric(
                    label: 'Total payable',
                    value: 'KES ${_money(loan.totalPayable)}'),
                _Metric(
                    label: 'Balance',
                    value: 'KES ${_money(loan.balanceRemaining)}'),
                _Metric(
                    label: 'Duration',
                    value: '${loan.durationMonths} month(s)'),
                if (loan.dueDate != null)
                  _Metric(label: 'Due date', value: _date(loan.dueDate!)),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Guarantors',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            ...loan.guarantors.map(
              (guarantor) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${guarantor.guarantorName} • KES ${_money(guarantor.amountGuaranteed)} • ${guarantor.status}',
                ),
              ),
            ),
            if (loan.repayments.isNotEmpty) ...[
              const Divider(height: 28),
              Text('Repayments', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...loan.repayments.map(
                (repayment) => Row(
                  children: [
                    Expanded(
                      child: Text(
                        'KES ${_money(repayment.amount)} • ${repayment.status} • ${repayment.paymentMethod}',
                      ),
                    ),
                    if (canManage && repayment.status == 'PENDING')
                      Wrap(
                        children: [
                          TextButton(
                            onPressed: () => onRejectRepayment(repayment),
                            child: const Text('Reject'),
                          ),
                          TextButton(
                            onPressed: () => onVerifyRepayment(repayment),
                            child: const Text('Verify'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            if (loan.installments.isNotEmpty) ...[
              const Divider(height: 28),
              Text('Installment schedule',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              ...loan.installments.map(
                (installment) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                      'Installment ${installment.installmentNumber} - ${_date(installment.dueDate)}'),
                  subtitle: Text(
                      'Principal KES ${_money(installment.principalAmount)} | Interest KES ${_money(installment.interestAmount)}'),
                  trailing: Text(
                    '${installment.status}\nKES ${_money(installment.totalDue)}',
                    textAlign: TextAlign.end,
                  ),
                ),
              ),
            ],
            if (isPendingGuarantor ||
                (canManage &&
                    (loan.status == 'PENDING_APPROVAL' ||
                        loan.status == 'APPROVED')) ||
                (isBorrower && loan.status == 'DISBURSED') ||
                (canManage && pendingRepayments.isNotEmpty))
              const SizedBox(height: 12),
            if (isPendingGuarantor)
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: onRejectGuarantee,
                    child: const Text('Reject guarantee'),
                  ),
                  FilledButton(
                    onPressed: onAcceptGuarantee,
                    child: const Text('Accept guarantee'),
                  ),
                ],
              ),
            if (canManage && loan.status == 'PENDING_APPROVAL')
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject loan'),
                  ),
                  FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Approve loan'),
                  ),
                ],
              ),
            if (canManage && loan.status == 'APPROVED')
              FilledButton.icon(
                onPressed: onDisburse,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Record disbursement'),
              ),
            if (isBorrower && loan.status == 'DISBURSED')
              FilledButton.icon(
                onPressed: onRepay,
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Make repayment'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'REPAID' => AppColors.success,
      'REJECTED' || 'DEFAULTED' => AppColors.error,
      'DISBURSED' => Colors.indigo,
      'APPROVED' => Colors.teal,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_outlined,
                size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('No loans yet'),
            SizedBox(height: 4),
            Text('Apply for a loan or wait for a guarantor request.'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade900)),
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

int? _asInt(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');
