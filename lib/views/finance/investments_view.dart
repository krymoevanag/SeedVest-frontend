import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../widgets/custom_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/add_investment_dialog.dart';
import 'investment_details_view.dart';
import '../../data/models/investment.dart';

class InvestmentsView extends StatefulWidget {
  const InvestmentsView({super.key});

  @override
  State<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends State<InvestmentsView> {
  final Set<int> _approvingIds = <int>{};
  final Set<int> _rejectingIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<GovernanceViewModel>();
      viewModel.fetchInvestments();
      viewModel.fetchGroups(); // Pre-fetch groups for the add dialog
    });
  }

  void _showAddInvestmentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddInvestmentDialog(),
    );

    if (result == true && mounted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment proposal mapped out successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _approveFromList(Investment investment) async {
    final governanceViewModel = context.read<GovernanceViewModel>();
    if (_approvingIds.contains(investment.id) ||
        _rejectingIds.contains(investment.id)) {
      return;
    }

    setState(() => _approvingIds.add(investment.id));
    final success = await governanceViewModel.approveInvestment(
      investment.id,
      notes: 'Approved via proposals list',
    );

    if (!mounted) {
      return;
    }
    setState(() => _approvingIds.remove(investment.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Investment approved successfully.'
            : 'Failed to approve investment.'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _rejectFromList(Investment investment) async {
    final governanceViewModel = context.read<GovernanceViewModel>();
    if (_approvingIds.contains(investment.id) ||
        _rejectingIds.contains(investment.id)) {
      return;
    }

    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Proposal'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = noteController.text.trim();
              if (value.isEmpty) {
                return;
              }
              Navigator.pop(context, value);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (note == null || note.isEmpty) {
      return;
    }

    setState(() => _rejectingIds.add(investment.id));
    final success =
        await governanceViewModel.rejectInvestment(investment.id, note);

    if (!mounted) {
      return;
    }
    setState(() => _rejectingIds.remove(investment.id));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Investment rejected successfully.'
            : 'Failed to reject investment.'),
        backgroundColor: success ? Colors.orange : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final canReviewProposals =
        userViewModel.isAdmin || userViewModel.isTreasurer;

    // Divide investments into Proposals vs Active/Matured
    final proposals = viewModel.investments
        .where((inv) =>
            ['DRAFT', 'PENDING_APPROVAL', 'REJECTED'].contains(inv.status))
        .toList();
    final activeInvestments = viewModel.investments
        .where((inv) =>
            !['DRAFT', 'PENDING_APPROVAL', 'REJECTED'].contains(inv.status))
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 10,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Investments'),
              Tab(text: 'Proposals'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: TabBarView(
          children: [
            _buildInvestmentList(activeInvestments, viewModel.isLoading,
                viewModel.fetchInvestments,
                canReviewProposals: false),
            _buildInvestmentList(
              proposals,
              viewModel.isLoading,
              viewModel.fetchInvestments,
              canReviewProposals: canReviewProposals,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddInvestmentDialog(context),
          label: const Text('Propose / Add'),
          icon: const Icon(Icons.add_business),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildInvestmentList(
    List<Investment> investments,
    bool isLoading,
    Future<void> Function() onRefresh, {
    required bool canReviewProposals,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: isLoading && investments.isEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: 5,
              itemBuilder: (context, index) => const ShimmerListTile(),
            )
          : investments.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(
                        child: Text('No investments found in this category.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final investment = investments[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InvestmentDetailsView(investment: investment),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        investment.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (investment.groupName != null)
                                        Text(
                                          investment.groupName!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                _StatusBadge(status: investment.status),
                              ],
                            ),
                            if (canReviewProposals &&
                                investment.status == 'PENDING_APPROVAL') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: (_approvingIds
                                                  .contains(investment.id) ||
                                              _rejectingIds
                                                  .contains(investment.id))
                                          ? null
                                          : () => _rejectFromList(investment),
                                      icon: _rejectingIds
                                              .contains(investment.id)
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.close,
                                              color: Colors.red,
                                            ),
                                      label: const Text(
                                        'Reject',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side:
                                            const BorderSide(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: (_approvingIds
                                                  .contains(investment.id) ||
                                              _rejectingIds
                                                  .contains(investment.id))
                                          ? null
                                          : () => _approveFromList(investment),
                                      icon: _approvingIds
                                              .contains(investment.id)
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.check),
                                      label: const Text('Approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              investment.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Amount Invested',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(
                                      currencyFormat
                                          .format(investment.amountInvested),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Expected ROI',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(
                                      '${investment.expectedRoiPercentage}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'PENDING_APPROVAL':
        color = Colors.orange;
        break;
      case 'REJECTED':
      case 'CANCELLED':
        color = Colors.red;
        break;
      case 'COMPLETED':
      case 'MATURED':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
