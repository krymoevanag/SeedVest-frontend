import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../core/theme/colors.dart';

class SavingsTargetsView extends StatefulWidget {
  const SavingsTargetsView({super.key});

  @override
  State<SavingsTargetsView> createState() => _SavingsTargetsViewState();
}

class _SavingsTargetsViewState extends State<SavingsTargetsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinanceViewModel>().fetchSavingsTargets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings Goals')),
      body: Consumer<FinanceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.savingsTargets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.savingsTargets.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.savingsTargets.length,
            itemBuilder: (context, index) {
              final target = viewModel.savingsTargets[index];
              return _buildTargetCard(target);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTargetDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No targets set yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showCreateTargetDialog,
            child: const Text('Create your first goal'),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(dynamic target) {
    final progress =
        (target['current_amount'] / target['target_amount']).clamp(0.0, 1.0);
    final isCompleted = target['status'] == 'COMPLETED';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  target['name'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green)
                else
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : AppColors.primary,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UGX ${target['current_amount']}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Goal: UGX ${target['target_amount']}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTargetDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set New Savings Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Goal Name (e.g. Land Purchase)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration:
                    const InputDecoration(labelText: 'Target Amount (UGX)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final success = await context
                      .read<FinanceViewModel>()
                      .createSavingsTarget({
                    'name': nameController.text,
                    'target_amount': double.parse(amountController.text),
                  });
                  if (success && mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
