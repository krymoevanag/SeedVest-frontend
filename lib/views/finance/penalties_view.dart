import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/penalties_viewmodel.dart';
import '../widgets/custom_card.dart';

class PenaltiesView extends StatefulWidget {
  const PenaltiesView({super.key});

  @override
  State<PenaltiesView> createState() => _PenaltiesViewState();
}

class _PenaltiesViewState extends State<PenaltiesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PenaltiesViewModel>().fetchPenalties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PenaltiesViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(title: const Text('Penalty Ledger')),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchPenalties,
        child: viewModel.isLoading && viewModel.penalties.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: viewModel.penalties.length,
                itemBuilder: (context, index) {
                  final penalty = viewModel.penalties[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.1),
                          child:
                              const Icon(Icons.gavel, color: AppColors.error),
                        ),
                        title: Text(
                          penalty.reason,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            DateFormat('MMM dd, yyyy').format(penalty.date)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(penalty.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                            Text(
                              penalty.status,
                              style: TextStyle(
                                color: penalty.status == 'PAID'
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
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
}
