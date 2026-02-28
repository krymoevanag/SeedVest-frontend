import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/app_theme.dart';
import '../finance/investments_view.dart';

class InvestmentManagementView extends StatefulWidget {
  const InvestmentManagementView({super.key});

  @override
  State<InvestmentManagementView> createState() =>
      _InvestmentManagementViewState();
}

class _InvestmentManagementViewState extends State<InvestmentManagementView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business),
            onPressed: () => _showAddInvestmentDialog(context),
            tooltip: 'Add New Investment',
          ),
        ],
      ),
      body: const InvestmentsView(),
    );
  }

  void _showAddInvestmentDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final roiController = TextEditingController();
    int? selectedGroupId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Group Investment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<GovernanceViewModel>(
                      builder: (context, viewModel, child) {
                        return DropdownButtonFormField<int>(
                          value: selectedGroupId,
                          decoration:
                              const InputDecoration(labelText: 'Target Group'),
                          items: viewModel.groups.map((g) {
                            return DropdownMenuItem<int>(
                              value: g.id,
                              child: Text(g.name),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setDialogState(() => selectedGroupId = val),
                        );
                      },
                    ),
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(labelText: 'Investment Title'),
                    ),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                          labelText: 'Principal Amount (UGX)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: roiController,
                      decoration:
                          const InputDecoration(labelText: 'Expected ROI (%)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedGroupId != null &&
                        titleController.text.isNotEmpty) {
                      final success = await context
                          .read<GovernanceViewModel>()
                          .createInvestment({
                        'group': selectedGroupId,
                        'name': titleController.text,
                        'principal_amount': double.parse(amountController.text),
                        'expected_return_rate':
                            double.parse(roiController.text),
                        'status': 'ACTIVE',
                        'start_date':
                            DateTime.now().toIso8601String().split('T')[0],
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
      },
    );
  }
}
