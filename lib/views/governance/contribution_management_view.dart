import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_card.dart';

class ContributionManagementView extends StatefulWidget {
  const ContributionManagementView({super.key});

  @override
  State<ContributionManagementView> createState() =>
      _ContributionManagementViewState();
}

class _ContributionManagementViewState
    extends State<ContributionManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionsViewModel>().fetchContributions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    // Only show PENDING contributions for management
    final pendingContributions =
        viewModel.contributions.where((c) => c.status == 'PENDING').toList();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(title: const Text('Contribution Management')),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingContributions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No pending contributions',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.fetchContributions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingContributions.length,
                    itemBuilder: (context, index) {
                      final contribution = pendingContributions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Member ID: ${contribution.userId}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      currencyFormat
                                          .format(contribution.amount),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Submitted: ${DateFormat('dd MMM yyyy').format(contribution.date)}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                                if (contribution.transactionId != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tx ID: ${contribution.transactionId}',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _confirmAction(
                                            context, 'reject', contribution.id),
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red),
                                        child: const Text('Reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _confirmAction(context,
                                            'approve', contribution.id),
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary),
                                        child: const Text('Approve'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _confirmAction(BuildContext context, String action, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${action[0].toUpperCase()}${action.substring(1)} Contribution'),
        content: Text('Are you sure you want to $action this contribution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final viewModel = Provider.of<ContributionsViewModel>(
                  this.context,
                  listen: false);
              if (action == 'approve') {
                viewModel.approveContribution(id);
              } else {
                viewModel.rejectContribution(id);
              }
              Navigator.pop(context);
            },
            child: Text(action[0].toUpperCase() + action.substring(1),
                style: TextStyle(
                    color:
                        action == 'approve' ? AppColors.primary : Colors.red)),
          ),
        ],
      ),
    );
  }
}
