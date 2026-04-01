import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/penalties_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
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
    final hasItems = viewModel.penalties.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Penalty Ledger')),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchPenalties,
        child: viewModel.isLoading && !hasItems
            ? const Center(child: CircularProgressIndicator())
            : !hasItems
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      const SizedBox(height: 100),
                      Icon(Icons.gavel_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          viewModel.errorMessage ?? 'No penalties found.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.penalties.length,
                    itemBuilder: (context, index) {
                      final penalty = viewModel.penalties[index];
                      final memberLabel = (penalty.userName != null &&
                              penalty.userName!.trim().isNotEmpty)
                          ? penalty.userName!
                          : (penalty.userId != null
                              ? 'Member #${penalty.userId}'
                              : 'Unknown member');
                      final groupLabel = (penalty.groupName != null &&
                              penalty.groupName!.trim().isNotEmpty)
                          ? penalty.groupName!
                          : 'No group';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.error.withValues(alpha: 0.1),
                              child: const Icon(Icons.gavel,
                                  color: AppColors.error),
                            ),
                            title: Text(
                              penalty.reason.isEmpty
                                  ? 'Penalty'
                                  : penalty.reason,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('MMM dd, yyyy')
                                    .format(penalty.date)),
                                const SizedBox(height: 2),
                                Text(
                                  '$memberLabel • $groupLabel',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
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
                                if (context.read<UserViewModel>().isTreasurer ||
                                    context.read<UserViewModel>().isAdmin)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.grey, size: 20),
                                    onPressed: () => _showArchiveDialog(
                                        context, viewModel, penalty.id),
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

  void _showArchiveDialog(
      BuildContext context, PenaltiesViewModel viewModel, int id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Archive Penalty"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Are you sure you want to archive this penalty? This action will be audit-logged and the Financial Secretary will be notified."),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason for archiving",
                hintText: "e.g., Logged incorrectly",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a reason")),
                );
                return;
              }

              final success = await viewModel.archivePenalty(id, reason);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Penalty archived successfully"
                        : "Failed to archive penalty"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text("Archive"),
          ),
        ],
      ),
    );
  }
}
