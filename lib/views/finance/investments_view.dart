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

class InvestmentsView extends StatefulWidget {
  const InvestmentsView({super.key});

  @override
  State<InvestmentsView> createState() => _InvestmentsViewState();
}

class _InvestmentsViewState extends State<InvestmentsView> {
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
          content: Text('Investment created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final canAddInvestment = userViewModel.isAdmin || userViewModel.isTreasurer;
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: viewModel.fetchInvestments,
        child: viewModel.isLoading && viewModel.investments.isEmpty
            ? ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 5,
                itemBuilder: (context, index) => const ShimmerListTile(),
              )
            : viewModel.investments.isEmpty
                ? const Center(child: Text('No active investments found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.investments.length,
                    itemBuilder: (context, index) {
                      final investment = viewModel.investments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CustomCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InvestmentDetailsView(
                                    investment: investment),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              const SizedBox(height: 8),
                              Text(
                                investment.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Amount Invested',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
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
                                              fontSize: 12,
                                              color: Colors.grey)),
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
      ),
      floatingActionButton: canAddInvestment
          ? FloatingActionButton.extended(
              onPressed: () => _showAddInvestmentDialog(context),
              label: const Text('Add Investment'),
              icon: const Icon(Icons.add_business),
              backgroundColor: AppColors.primary,
            )
          : null,
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
        color = Colors.green;
        break;
      case 'COMPLETED':
        color = Colors.blue;
        break;
      case 'PENDING':
        color = Colors.orange;
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
        status,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
