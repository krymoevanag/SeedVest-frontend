import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../data/models/loan.dart';
import '../../viewmodels/loan_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../widgets/custom_card.dart';

class LoansOverviewView extends StatefulWidget {
  const LoansOverviewView({super.key});

  @override
  State<LoansOverviewView> createState() => _LoansOverviewViewState();
}

class _LoansOverviewViewState extends State<LoansOverviewView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'KES ');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanViewModel>().initialise();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final currentUserId = userViewModel.currentUser?.id;
    final canManage = userViewModel.isAdmin || userViewModel.isTreasurer;
    final tabCount = canManage ? 3 : 2;

    if (_tabController.length != tabCount) {
      _tabController.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Loans'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh loans',
            onPressed: () => context.read<LoanViewModel>().fetchLoans(),
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          tabs: [
            const Tab(text: 'My Loans'),
            const Tab(text: 'Guarantor Requests'),
            if (canManage) const Tab(text: 'Group Oversight'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplicationBottomSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Apply for Loan'),
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

          final myLoansList = currentUserId != null
              ? loansViewModel.myLoans(currentUserId)
              : <Loan>[];
          final guarantorLoansList = currentUserId != null
              ? loansViewModel.guarantorLoans(currentUserId)
              : <Loan>[];
          final allGroupLoansList = loansViewModel.groupLoans();

          return Column(
            children: [
              // ── Top Metrics Banner ───────────────────────────────────────
              if (currentUserId != null)
                _LoansSummaryBanner(
                  totalBorrowed: loansViewModel.totalBorrowed(currentUserId),
                  totalOutstanding:
                      loansViewModel.totalOutstanding(currentUserId),
                  activeLoansCount:
                      loansViewModel.activeLoansCount(currentUserId),
                  currencyFormat: _currencyFormat,
                ),

              // ── Tab Views ────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: My Loans
                    _LoanListTab(
                      loans: myLoansList,
                      emptyMessage:
                          'You have no loan applications or active loans.',
                      currentUserId: currentUserId,
                      canManage: false,
                      onRefresh: loansViewModel.fetchLoans,
                      currencyFormat: _currencyFormat,
                      onRepay: _showRepaymentBottomSheet,
                    ),

                    // Tab 2: Guarantor Requests
                    _LoanListTab(
                      loans: guarantorLoansList,
                      emptyMessage:
                          'You have no pending guarantor requests.',
                      currentUserId: currentUserId,
                      canManage: false,
                      onRefresh: loansViewModel.fetchLoans,
                      currencyFormat: _currencyFormat,
                      onAcceptGuarantee: (loan) =>
                          _respondToGuarantee(loan, true),
                      onRejectGuarantee: (loan) =>
                          _respondToGuarantee(loan, false),
                    ),

                    // Tab 3: Group Oversight (Admins/Treasurers only)
                    if (canManage)
                      _LoanListTab(
                        loans: allGroupLoansList,
                        emptyMessage: 'No loans found in your group.',
                        currentUserId: currentUserId,
                        canManage: true,
                        onRefresh: loansViewModel.fetchLoans,
                        currencyFormat: _currencyFormat,
                        onApprove: (loan) => _performAction(
                          title: 'Approve Loan',
                          prompt:
                              'Approve loan #${loan.id} of KES ${_currencyFormat.format(loan.amount)} for ${loan.borrowerName}?',
                          action: () => loansViewModel.approveLoan(loan.id),
                        ),
                        onReject: (loan) => _performReasonAction(
                          title: 'Reject Loan',
                          prompt:
                              'Please provide a reason for rejecting this loan:',
                          action: (reason) =>
                              loansViewModel.rejectLoan(loan.id, reason),
                        ),
                        onDisburse: (loan) => _performAction(
                          title: 'Disburse Loan',
                          prompt:
                              'Mark loan #${loan.id} as disbursed? Installments schedule will be generated.',
                          action: () => loansViewModel.disburseLoan(loan.id),
                        ),
                        onVerifyRepayment: (repayment) => _performAction(
                          title: 'Verify Repayment',
                          prompt:
                              'Verify payment of ${_currencyFormat.format(repayment.amount)} from ${repayment.userName}?',
                          action: () => loansViewModel.verifyRepayment(
                              repayment.loanId, repayment.id),
                        ),
                        onRejectRepayment: (repayment) => _performReasonAction(
                          title: 'Reject Repayment',
                          prompt:
                              'Please specify reason for rejecting repayment #${repayment.id}:',
                          action: (reason) => loansViewModel.rejectRepayment(
                              repayment.loanId, repayment.id, reason),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _respondToGuarantee(Loan loan, bool accepted) async {
    final loanViewModel = context.read<LoanViewModel>();
    final success =
        await loanViewModel.respondToGuarantee(loan.id, accepted);
    if (!mounted) return;
    _showMessage(
      success
          ? (accepted ? 'Guarantee accepted.' : 'Guarantee declined.')
          : (loanViewModel.error ?? 'Action failed.'),
      success: success,
    );
  }

  Future<void> _showApplicationBottomSheet() async {
    final loanViewModel = context.read<LoanViewModel>();
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final purposeController = TextEditingController();
    int? selectedGroupId = loanViewModel.groups.isNotEmpty
        ? _asInt(loanViewModel.groups.first['id'])
        : null;
    double interestRate = 5.0;
    int durationMonths = 1;
    double amount = 0.0;
    final Set<int> guarantorIds = <int>{};

    if (selectedGroupId != null) {
      await loanViewModel.fetchEligibleGuarantors(selectedGroupId);
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final calculatedTotal = loanViewModel.calculateTotalPayable(
            amount: amount,
            interestRate: interestRate,
            durationMonths: durationMonths,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Apply for Loan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Group Selection
                    DropdownButtonFormField<int>(
                      initialValue: selectedGroupId,
                      decoration: const InputDecoration(
                        labelText: 'Select Group',
                        border: OutlineInputBorder(),
                      ),
                      items: loanViewModel.groups
                          .map(
                            (group) => DropdownMenuItem<int>(
                              value: _asInt(group['id']),
                              child: Text(
                                group['name']?.toString() ?? 'Group',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        setModalState(() {
                          selectedGroupId = value;
                          guarantorIds.clear();
                        });
                        if (value != null) {
                          await loanViewModel.fetchEligibleGuarantors(value);
                          if (mounted) setModalState(() {});
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a group.' : null,
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Requested Amount (KES)',
                        prefixText: 'KES ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setModalState(
                            () => amount = double.tryParse(value) ?? 0.0);
                      },
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '') ?? 0.0;
                        if (parsed <= 0) return 'Enter a valid amount.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Duration Slider
                    Text(
                      'Repayment Duration: $durationMonths month${durationMonths == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      min: 1,
                      max: 12,
                      divisions: 11,
                      value: durationMonths.toDouble(),
                      activeColor: AppColors.primary,
                      onChanged: (v) =>
                          setModalState(() => durationMonths = v.round()),
                    ),

                    // Interest rate
                    Text(
                      'Interest per Month: ${interestRate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      min: 5,
                      max: 10,
                      divisions: 10,
                      value: interestRate,
                      activeColor: AppColors.secondary,
                      onChanged: (v) =>
                          setModalState(() => interestRate = v),
                    ),

                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Payable',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                _currencyFormat.format(calculatedTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Total Interest',
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                _currencyFormat.format(calculatedTotal - amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Purpose
                    TextFormField(
                      controller: purposeController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Purpose of Loan (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Guarantors section
                    const Text(
                      'Select Eligible Guarantors (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (loanViewModel.eligibleGuarantors.isEmpty)
                      const Text(
                        'No other eligible group members available.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      ...loanViewModel.eligibleGuarantors.map((g) {
                        final gId = _asInt(g['id']);
                        final isSelected = guarantorIds.contains(gId);
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(g['name']?.toString() ?? 'Member'),
                          subtitle: Text(
                            'Savings: KES ${_money(g['total_savings'])}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          value: isSelected,
                          onChanged: (checked) {
                            setModalState(() {
                              if (checked == true) {
                                guarantorIds.add(gId);
                              } else {
                                guarantorIds.remove(gId);
                              }
                            });
                          },
                        );
                      }),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          if (selectedGroupId == null) return;

                          final success = await loanViewModel.applyLoan(
                            groupId: selectedGroupId!,
                            amount: amount,
                            interestRate: interestRate,
                            durationMonths: durationMonths,
                            purpose: purposeController.text.trim(),
                            guarantorUserIds: guarantorIds.toList(),
                          );

                          if (!context.mounted) return;
                          if (success) {
                            Navigator.pop(context);
                          }
                          _showMessage(
                            success
                                ? 'Loan application submitted successfully.'
                                : (loanViewModel.error ??
                                    'Failed to apply for loan.'),
                            success: success,
                          );
                        },
                        child: const Text('Submit Application'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showRepaymentBottomSheet(Loan loan) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: loan.balanceRemaining > 0
          ? loan.balanceRemaining.toStringAsFixed(2)
          : '',
    );
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'MPESA';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setRepayState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Repay Loan #${loan.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Remaining balance banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Outstanding Loan Balance',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(loan.balanceRemaining),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF00695C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MPESA', child: Text('M-Pesa')),
                      DropdownMenuItem(
                          value: 'BANK_TRANSFER', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'CASH', child: Text('Cash')),
                    ],
                    onChanged: (v) {
                      if (v != null) setRepayState(() => paymentMethod = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Repayment Amount
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Repayment Amount (KES)',
                      prefixText: 'KES ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '') ?? 0.0;
                      if (val <= 0) return 'Enter a positive amount.';
                      if (val > loan.balanceRemaining) {
                        return 'Amount cannot exceed remaining balance.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Transaction Reference
                  TextFormField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Reference (e.g. MPESA code)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                        if (success) Navigator.pop(ctx);
                        _showMessage(
                          success
                              ? 'Repayment submitted for verification.'
                              : (loanViewModel.error ?? 'Repayment failed.'),
                          success: success,
                        );
                      },
                      child: const Text('Submit Repayment'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
            child: const Text('Submit'),
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

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _money(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}

// ── Loans Summary Banner ────────────────────────────────────────────────────

class _LoansSummaryBanner extends StatelessWidget {
  const _LoansSummaryBanner({
    required this.totalBorrowed,
    required this.totalOutstanding,
    required this.activeLoansCount,
    required this.currencyFormat,
  });

  final double totalBorrowed;
  final double totalOutstanding;
  final int activeLoansCount;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BannerMetric(
            label: 'Total Borrowed',
            value: currencyFormat.format(totalBorrowed),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          _BannerMetric(
            label: 'Outstanding',
            value: currencyFormat.format(totalOutstanding),
            highlight: totalOutstanding > 0,
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          _BannerMetric(
            label: 'Active Loans',
            value: '$activeLoansCount',
          ),
        ],
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: highlight ? Colors.amber[200] : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ── Tab ListView Widget ─────────────────────────────────────────────────────

class _LoanListTab extends StatelessWidget {
  const _LoanListTab({
    required this.loans,
    required this.emptyMessage,
    required this.currentUserId,
    required this.canManage,
    required this.onRefresh,
    required this.currencyFormat,
    this.onRepay,
    this.onAcceptGuarantee,
    this.onRejectGuarantee,
    this.onApprove,
    this.onReject,
    this.onDisburse,
    this.onVerifyRepayment,
    this.onRejectRepayment,
  });

  final List<Loan> loans;
  final String emptyMessage;
  final int? currentUserId;
  final bool canManage;
  final Future<void> Function() onRefresh;
  final NumberFormat currencyFormat;
  final ValueChanged<Loan>? onRepay;
  final ValueChanged<Loan>? onAcceptGuarantee;
  final ValueChanged<Loan>? onRejectGuarantee;
  final ValueChanged<Loan>? onApprove;
  final ValueChanged<Loan>? onReject;
  final ValueChanged<Loan>? onDisburse;
  final ValueChanged<LoanRepayment>? onVerifyRepayment;
  final ValueChanged<LoanRepayment>? onRejectRepayment;

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.account_balance_outlined,
                      size: 56, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        itemCount: loans.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final loan = loans[index];
          return _LoanCardItem(
            loan: loan,
            currentUserId: currentUserId,
            canManage: canManage,
            currencyFormat: currencyFormat,
            onRepay: onRepay != null ? () => onRepay!(loan) : null,
            onAcceptGuarantee: onAcceptGuarantee != null
                ? () => onAcceptGuarantee!(loan)
                : null,
            onRejectGuarantee: onRejectGuarantee != null
                ? () => onRejectGuarantee!(loan)
                : null,
            onApprove: onApprove != null ? () => onApprove!(loan) : null,
            onReject: onReject != null ? () => onReject!(loan) : null,
            onDisburse: onDisburse != null ? () => onDisburse!(loan) : null,
            onVerifyRepayment: onVerifyRepayment,
            onRejectRepayment: onRejectRepayment,
          );
        },
      ),
    );
  }
}

// ── Individual Loan Card ────────────────────────────────────────────────────

class _LoanCardItem extends StatefulWidget {
  const _LoanCardItem({
    required this.loan,
    required this.currentUserId,
    required this.canManage,
    required this.currencyFormat,
    this.onRepay,
    this.onAcceptGuarantee,
    this.onRejectGuarantee,
    this.onApprove,
    this.onReject,
    this.onDisburse,
    this.onVerifyRepayment,
    this.onRejectRepayment,
  });

  final Loan loan;
  final int? currentUserId;
  final bool canManage;
  final NumberFormat currencyFormat;
  final VoidCallback? onRepay;
  final VoidCallback? onAcceptGuarantee;
  final VoidCallback? onRejectGuarantee;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDisburse;
  final ValueChanged<LoanRepayment>? onVerifyRepayment;
  final ValueChanged<LoanRepayment>? onRejectRepayment;

  @override
  State<_LoanCardItem> createState() => _LoanCardItemState();
}

class _LoanCardItemState extends State<_LoanCardItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final isBorrower = widget.currentUserId == loan.userId;
    final isPendingGuarantor = widget.currentUserId != null &&
        loan.isGuarantor(widget.currentUserId!) &&
        loan.status == 'PENDING_GUARANTORS';

    final totalPaid = loan.totalPayable - loan.balanceRemaining;
    final progress = loan.totalPayable > 0
        ? (totalPaid / loan.totalPayable).clamp(0.0, 1.0)
        : 0.0;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Group name & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  loan.groupName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusBadge(status: loan.status),
            ],
          ),
          const SizedBox(height: 6),

          // Borrower / Purpose
          Text(
            isBorrower ? 'Your Loan' : 'Borrower: ${loan.borrowerName}',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
          if (loan.purpose.isNotEmpty)
            Text(
              'Purpose: ${loan.purpose}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 12),

          // Key metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(
                label: 'Principal',
                value: widget.currencyFormat.format(loan.amount),
              ),
              _MetricItem(
                label: 'Total Payable',
                value: widget.currencyFormat.format(loan.totalPayable),
              ),
              _MetricItem(
                label: 'Remaining',
                value: widget.currencyFormat.format(loan.balanceRemaining),
                color: loan.balanceRemaining > 0
                    ? Colors.red[700]
                    : Colors.green[700],
              ),
            ],
          ),

          // Repayment Progress for Disbursed Loans
          if (loan.status == 'DISBURSED' || loan.status == 'REPAID') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                color: progress >= 1.0 ? Colors.green : AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% repaid',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (loan.dueDate != null)
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(loan.dueDate!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ],

          // Expand / Collapse details toggle
          const SizedBox(height: 10),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _expanded ? 'Hide Details' : 'View Installments & Guarantors',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),

          // Expanded section
          if (_expanded) ...[
            const Divider(height: 20),
            if (loan.guarantors.isNotEmpty) ...[
              const Text('Guarantors',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              ...loan.guarantors.map((g) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• ${g.guarantorName}: ${widget.currencyFormat.format(g.amountGuaranteed)} (${g.status})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )),
            ],
            if (loan.installments.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Installments Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              ...loan.installments.map((inst) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inst. ${inst.installmentNumber} (${DateFormat('MMM dd').format(inst.dueDate)})',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${widget.currencyFormat.format(inst.totalDue)} [${inst.status}]',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: inst.status == 'PAID'
                                ? Colors.green
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],

          // Action Buttons
          if (isPendingGuarantor ||
              (isBorrower && loan.status == 'DISBURSED') ||
              (widget.canManage &&
                  (loan.status == 'PENDING_APPROVAL' ||
                      loan.status == 'APPROVED'))) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isPendingGuarantor) ...[
                  OutlinedButton(
                    onPressed: widget.onRejectGuarantee,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onAcceptGuarantee,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Accept Guarantee'),
                  ),
                ],
                if (isBorrower && loan.status == 'DISBURSED')
                  FilledButton.icon(
                    onPressed: widget.onRepay,
                    icon: const Icon(Icons.payment, size: 16),
                    label: const Text('Repay Loan'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00695C),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                if (widget.canManage && loan.status == 'PENDING_APPROVAL') ...[
                  OutlinedButton(
                    onPressed: widget.onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onApprove,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Approve'),
                  ),
                ],
                if (widget.canManage && loan.status == 'APPROVED')
                  FilledButton(
                    onPressed: widget.onDisburse,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Disburse'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Status Badge ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case 'APPROVED':
      case 'DISBURSED':
      case 'REPAID':
        bg = Colors.green.withValues(alpha: 0.12);
        fg = Colors.green[800]!;
        break;
      case 'PENDING_GUARANTORS':
      case 'PENDING_APPROVAL':
      case 'PENDING':
        bg = Colors.orange.withValues(alpha: 0.12);
        fg = Colors.orange[800]!;
        break;
      case 'REJECTED':
      case 'DEFAULTED':
        bg = Colors.red.withValues(alpha: 0.12);
        fg = Colors.red[800]!;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.12);
        fg = Colors.grey[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
