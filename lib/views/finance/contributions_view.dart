import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../widgets/custom_card.dart';
import '../widgets/contribution_bottom_sheet.dart';

class ContributionsView extends StatefulWidget {
  const ContributionsView({super.key});

  @override
  State<ContributionsView> createState() => _ContributionsViewState();
}

class _ContributionsViewState extends State<ContributionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionsViewModel>().fetchContributions();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
      case 'LATE':
      case 'SUCCESS':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showContributionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ContributionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: viewModel.fetchContributions,
        child: viewModel.isLoading && viewModel.contributions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: viewModel.contributions.length,
                itemBuilder: (context, index) {
                  final contribution = viewModel.contributions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.account_balance_wallet,
                              color: AppColors.primary),
                        ),
                        title: Text(
                          currencyFormat.format(contribution.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              contribution.isManualEntry
                                  ? '${DateFormat('MMM dd, yyyy - HH:mm').format(contribution.date)} - Manual proposal'
                                  : DateFormat('MMM dd, yyyy - HH:mm')
                                      .format(contribution.date),
                            ),
                            if (contribution.contributionMonth != null)
                              Text(
                                'Month: ${DateFormat('MMM yyyy').format(contribution.contributionMonth!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if ((contribution.rejectionReason ?? '')
                                .trim()
                                .isNotEmpty)
                              Text(
                                'Reason: ${contribution.rejectionReason}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(contribution.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            contribution.status,
                            style: TextStyle(
                              color: _statusColor(contribution.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContributionSheet(context),
        label: const Text('New Contribution'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
