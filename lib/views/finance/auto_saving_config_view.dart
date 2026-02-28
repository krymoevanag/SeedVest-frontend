import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/colors.dart';

class AutoSavingConfigView extends StatefulWidget {
  const AutoSavingConfigView({super.key});

  @override
  State<AutoSavingConfigView> createState() => _AutoSavingConfigViewState();
}

class _AutoSavingConfigViewState extends State<AutoSavingConfigView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int _dayOfMonth = 1;
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<FinanceViewModel>();
      await viewModel.fetchAutoSavingConfigs();
      final gViewModel = context.read<GovernanceViewModel>();
      final groups = await gViewModel.fetchGroups();
      if (groups.isNotEmpty) {
        setState(() {
          _selectedGroupId = groups.first.id;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auto-Saving Setup')),
      body: Consumer<FinanceViewModel>(
        builder: (context, viewModel, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildConfigForm(viewModel),
              const SizedBox(height: 24),
              const Text(
                'Active Configurations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (viewModel.autoSavingConfigs.isEmpty)
                const Center(child: Text('No active auto-savings.'))
              else
                ...viewModel.autoSavingConfigs
                    .map((c) => _buildConfigCard(c, viewModel))
                    .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConfigForm(FinanceViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule New Auto-Saving',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Consumer<GovernanceViewModel>(
                builder: (context, gViewModel, child) {
                  return DropdownButtonFormField<int>(
                    value: _selectedGroupId,
                    decoration:
                        const InputDecoration(labelText: 'Target Group'),
                    items: gViewModel.groups.map((g) {
                      return DropdownMenuItem<int>(
                        value: g.id,
                        child: Text(g.name),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedGroupId = val),
                    validator: (v) => v == null ? 'Select a group' : null,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Monthly Amount (UGX)',
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter amount';
                  final amount = double.tryParse(val);
                  if (amount == null || amount < 500)
                    return 'Min amount is 500';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _dayOfMonth,
                decoration:
                    const InputDecoration(labelText: 'Day of Month (1-28)'),
                items: List.generate(28, (index) => index + 1).map((d) {
                  return DropdownMenuItem<int>(
                      value: d, child: Text(d.toString()));
                }).toList(),
                onChanged: (val) => setState(() => _dayOfMonth = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submit(viewModel),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: viewModel.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enable Auto-Saving'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(dynamic config, FinanceViewModel viewModel) {
    return Card(
      child: ListTile(
        title: Text('UGX ${config['amount']} Monthly'),
        subtitle: Text('On day ${config['day_of_month']} of every month'),
        trailing: Switch(
          value: config['is_active'],
          onChanged: (val) =>
              viewModel.updateAutoSavingConfig(config['id'], val),
        ),
      ),
    );
  }

  void _submit(FinanceViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.createAutoSavingConfig({
        'group': _selectedGroupId,
        'amount': double.parse(_amountController.text),
        'day_of_month': _dayOfMonth,
        'is_active': true,
      });

      if (success) {
        _amountController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auto-saving configured!')),
          );
        }
      }
    }
  }
}
