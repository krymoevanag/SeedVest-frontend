import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';

class AddInvestmentDialog extends StatefulWidget {
  const AddInvestmentDialog({super.key});

  @override
  State<AddInvestmentDialog> createState() => _AddInvestmentDialogState();
}

class _AddInvestmentDialogState extends State<AddInvestmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _roiController = TextEditingController();
  int? _selectedGroupId;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _roiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target group')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final viewModel = context.read<GovernanceViewModel>();
      final success = await viewModel.createInvestment({
        'group': _selectedGroupId,
        'name': _nameController.text.trim(),
        'amount_invested': double.parse(_amountController.text.trim()),
        'expected_roi_percentage': double.parse(_roiController.text.trim()),
        'status': 'ACTIVE',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create investment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Group Investment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<GovernanceViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.groups.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                          'No groups available. Ensure you are an admin/treasurer.'),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Target Group',
                      border: OutlineInputBorder(),
                    ),
                    items: viewModel.groups.map((g) {
                      return DropdownMenuItem<int>(
                        value: g['id'],
                        child: Text(g['name']),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) => setState(() => _selectedGroupId = val),
                    validator: (val) =>
                        val == null ? 'Target group is required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Investment Name',
                  hintText: 'e.g. Real Estate Project A',
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    (val == null || val.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Principal Amount (KES)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Amount is required';
                  if (double.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roiController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Expected ROI (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'ROI is required';
                  if (double.tryParse(val) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
