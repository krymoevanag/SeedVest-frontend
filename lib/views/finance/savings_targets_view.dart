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
    DateTime? selectedDeadline;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Set New Savings Goal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name (e.g. Land Purchase)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Target Amount (KES)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDeadline = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Deadline (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDeadline != null
                              ? "${selectedDeadline!.year}-${selectedDeadline!.month.toString().padLeft(2, '0')}-${selectedDeadline!.day.toString().padLeft(2, '0')}"
                              : 'Select a date',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.isNotEmpty &&
                              amountController.text.isNotEmpty) {
                            setDialogState(() => isSubmitting = true);

                            final amount =
                                double.tryParse(amountController.text);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please enter a valid amount')),
                              );
                              setDialogState(() => isSubmitting = false);
                              return;
                            }

                            final data = {
                              'name': nameController.text,
                              'target_amount': amount,
                              'start_date': DateTime.now()
                                  .toIso8601String()
                                  .split('T')[0],
                            };

                            if (selectedDeadline != null) {
                              data['deadline'] = selectedDeadline!
                                  .toIso8601String()
                                  .split('T')[0];
                            }

                            final success = await dialogContext
                                .read<FinanceViewModel>()
                                .createSavingsTarget(data);

                            if (success && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            } else {
                              if (dialogContext.mounted) {
                                setDialogState(() => isSubmitting = false);
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ))
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
