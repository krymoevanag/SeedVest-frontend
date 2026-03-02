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

  // Basic Info
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _purposeController = TextEditingController();
  final _businessCaseController = TextEditingController();

  // Financial specifics
  final _amountController = TextEditingController();
  final _roiController = TextEditingController();
  final _minCapitalController = TextEditingController();

  // Timeline specifics
  final _durationController = TextEditingController();
  final _lockInPeriodController = TextEditingController();

  int? _selectedGroupId;
  String _returnType = 'FIXED';
  String _payoutFrequency = 'AT_MATURITY';
  String _riskLevel = 'MEDIUM';

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _purposeController.dispose();
    _businessCaseController.dispose();
    _amountController.dispose();
    _roiController.dispose();
    _minCapitalController.dispose();
    _durationController.dispose();
    _lockInPeriodController.dispose();
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
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'business_case': _businessCaseController.text.trim(),
        'amount_invested': double.parse(_amountController.text.trim()),
        'expected_roi_percentage': double.parse(_roiController.text.trim()),
        'min_capital': _minCapitalController.text.isEmpty
            ? null
            : double.parse(_minCapitalController.text.trim()),
        'duration': _durationController.text.isEmpty
            ? null
            : int.parse(_durationController.text.trim()),
        'lock_in_period': _lockInPeriodController.text.isEmpty
            ? null
            : int.parse(_lockInPeriodController.text.trim()),
        'return_type': _returnType,
        'payout_frequency': _payoutFrequency,
        'risk_level': _riskLevel,
        'status': 'PENDING_APPROVAL',
        'start_date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create proposal. Please try again.'),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Propose/Add Investment',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader('Basic Details'),
                    Consumer<GovernanceViewModel>(
                      builder: (context, viewModel, child) {
                        if (viewModel.groups.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('No groups available to target.'),
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
                          border: OutlineInputBorder()),
                      validator: (val) => (val == null || val.isEmpty)
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !_isSubmitting,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _categoryController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _purposeController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Purpose',
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _businessCaseController,
                      enabled: !_isSubmitting,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Business Case (Optional)',
                          border: OutlineInputBorder()),
                    ),
                    _buildSectionHeader('Financials'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Principal Amount (KES)',
                                border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minCapitalController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Min Capital (Optional)',
                                border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _roiController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Expected ROI (%)',
                                border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Required';
                              if (double.tryParse(val) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _returnType,
                            decoration: const InputDecoration(
                                labelText: 'Return Type',
                                border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(
                                  value: 'FIXED', child: Text('Fixed')),
                              DropdownMenuItem(
                                  value: 'VARIABLE', child: Text('Variable')),
                              DropdownMenuItem(
                                  value: 'COMPOUND', child: Text('Compound')),
                              DropdownMenuItem(
                                  value: 'PROFIT_BASED',
                                  child: Text('Profit-based')),
                            ],
                            onChanged: _isSubmitting
                                ? null
                                : (val) => setState(() => _returnType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _riskLevel,
                      decoration: const InputDecoration(
                          labelText: 'Risk Level',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('Low')),
                        DropdownMenuItem(
                            value: 'MEDIUM', child: Text('Medium')),
                        DropdownMenuItem(value: 'HIGH', child: Text('High')),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (val) => setState(() => _riskLevel = val!),
                    ),
                    _buildSectionHeader('Timeline'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Duration (Months)',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lockInPeriodController,
                            enabled: !_isSubmitting,
                            decoration: const InputDecoration(
                                labelText: 'Lock-in (Months)',
                                border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _payoutFrequency,
                      decoration: const InputDecoration(
                          labelText: 'Payout Frequency',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: 'MONTHLY', child: Text('Monthly')),
                        DropdownMenuItem(
                            value: 'QUARTERLY', child: Text('Quarterly')),
                        DropdownMenuItem(
                            value: 'ANNUALLY', child: Text('Annually')),
                        DropdownMenuItem(
                            value: 'AT_MATURITY', child: Text('At Maturity')),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (val) => setState(() => _payoutFrequency = val!),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Submit Proposal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
