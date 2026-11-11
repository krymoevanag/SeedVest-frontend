import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/file_download_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/penalties_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../data/models/penalty.dart';
import '../widgets/custom_card.dart';
import 'penalty_statement_view.dart';

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

  Future<void> _exportCsv(List<Penalty> penalties) async {
    if (penalties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No penalties to export.')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final buffer = StringBuffer();
      buffer.writeln('Member,Group,Amount (KES),Reason,Issued Date,Status');
      for (final p in penalties) {
        final member = p.userName ?? 'Member #${p.userId}';
        final group = p.groupName ?? '';
        final reason = p.reason.replaceAll(',', ';');
        final issuedDate = dateFormat.format(p.date);
        buffer.writeln('"$member","$group",${p.amount},"$reason","$issuedDate","${p.status}"');
      }
      final timestamp = dateFormat.format(DateTime.now());
      final fileName = 'penalties_$timestamp.csv';
      final file = await FileDownloadService.instance.saveTextFile(
        fileName: fileName,
        content: buffer.toString(),
      );
      if (!mounted) return;
      FileDownloadService.instance.showDownloadCompleteSheet(
        context,
        filePath: file.path,
        fileName: fileName,
        fileTypeLabel: 'Penalties CSV',
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to export penalties. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PenaltiesViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final hasItems = viewModel.penalties.isNotEmpty;

    // Compute summary totals
    final totalAmount =
        viewModel.penalties.fold(0.0, (s, p) => s + p.amount);
    final unpaidAmount = viewModel.penalties
        .where((p) => p.status != 'PAID')
        .fold(0.0, (s, p) => s + p.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Penalty Ledger'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (hasItems)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Export Penalties CSV',
              onPressed: () => _exportCsv(viewModel.penalties),
            ),
        ],
      ),
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
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── Summary banner ───────────────────────────────────
                      _SummaryBanner(
                        total: totalAmount,
                        unpaid: unpaidAmount,
                        currencyFormat: currencyFormat,
                        count: viewModel.penalties.length,
                      ),
                      const SizedBox(height: 20),

                      // ── Penalty list ─────────────────────────────────────
                      ...List.generate(viewModel.penalties.length, (index) {
                        final penalty = viewModel.penalties[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PenaltyCard(
                            penalty: penalty,
                            currencyFormat: currencyFormat,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PenaltyStatementView(penalty: penalty),
                              ),
                            ),
                            onEdit: (context.read<UserViewModel>()
                                        .isTreasurer ||
                                    context.read<UserViewModel>().isAdmin)
                                ? () => _showEditDialog(
                                    context, viewModel, penalty)
                                : null,
                            onArchive: (context.read<UserViewModel>()
                                        .isTreasurer ||
                                    context.read<UserViewModel>().isAdmin)
                                ? () => _showArchiveDialog(
                                    context, viewModel, penalty.id)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ),
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, PenaltiesViewModel viewModel, Penalty penalty) {
    final amountController =
        TextEditingController(text: penalty.amount.toString());
    final reasonController = TextEditingController(text: penalty.reason);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Penalty"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Amount (KES)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Reason",
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
              final amount = double.tryParse(amountController.text.trim());
              final reason = reasonController.text.trim();
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please enter a valid penalty amount")),
                );
                return;
              }
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please provide a reason")),
                );
                return;
              }

              final success = await viewModel.updatePenalty(penalty.id, {
                'amount': amount,
                'reason': reason,
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? "Penalty updated successfully"
                        : "Failed to update penalty"),
                    backgroundColor:
                        success ? AppColors.success : AppColors.error,
                  ),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
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

// ── Summary banner ───────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({
    required this.total,
    required this.unpaid,
    required this.currencyFormat,
    required this.count,
  });

  final double total;
  final double unpaid;
  final NumberFormat currencyFormat;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B1FA2), Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count Penalt${count == 1 ? 'y' : 'ies'} on record',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13),
                ),
                Text(
                  currencyFormat.format(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (unpaid > 0)
                  Text(
                    '${currencyFormat.format(unpaid)} outstanding',
                    style: TextStyle(
                      color: Colors.orange[200],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual penalty card ─────────────────────────────────────────────────

class _PenaltyCard extends StatelessWidget {
  const _PenaltyCard({
    required this.penalty,
    required this.currencyFormat,
    required this.onTap,
    this.onEdit,
    this.onArchive,
  });

  final Penalty penalty;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final isPaid = penalty.status == 'PAID';
    final memberLabel =
        (penalty.userName != null && penalty.userName!.trim().isNotEmpty)
            ? penalty.userName!
            : (penalty.userId != null
                ? 'Member #${penalty.userId}'
                : 'You');
    final groupLabel =
        (penalty.groupName != null && penalty.groupName!.trim().isNotEmpty)
            ? penalty.groupName!
            : 'No group';

    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isPaid
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaid ? Icons.check_circle_outline : Icons.gavel,
              color: isPaid ? AppColors.success : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reason
                Text(
                  penalty.reason.isNotEmpty ? penalty.reason : 'Penalty',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Date
                Text(
                  DateFormat('MMM dd, yyyy').format(penalty.date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                // Member • Group
                Text(
                  '$memberLabel  ·  $groupLabel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Trailing: amount + badge + optional archive
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(penalty.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isPaid ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  penalty.status,
                  style: TextStyle(
                    color: isPaid ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    GestureDetector(
                      onTap: onEdit,
                      child: const Padding(
                        padding: EdgeInsets.only(top: 6, right: 8),
                        child: Icon(Icons.edit_outlined,
                            color: Colors.blueGrey, size: 18),
                      ),
                    ),
                  if (onArchive != null)
                    GestureDetector(
                      onTap: onArchive,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Icon(Icons.delete_outline,
                            color: Colors.grey[400], size: 18),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Chevron hint
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
