import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/finance_viewmodel.dart';
import '../../viewmodels/governance_viewmodel.dart';

class GroupSettingsView extends StatefulWidget {
  final Map<String, dynamic> group;
  const GroupSettingsView({super.key, required this.group});

  @override
  State<GroupSettingsView> createState() => _GroupSettingsViewState();
}

class _GroupSettingsViewState extends State<GroupSettingsView> {
  late String _interval;
  late double _minSaving;
  late double _penaltyAmount;
  late bool _penaltyEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _interval = widget.group['savings_interval'] ?? 'MONTHLY';
    _minSaving = double.tryParse(
            widget.group['min_saving_amount']?.toString() ?? '500') ??
        500;
    _penaltyAmount =
        double.tryParse(widget.group['penalty_amount']?.toString() ?? '100') ??
            100;
    _penaltyEnabled = widget.group['is_penalty_enabled'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings: ${widget.group['name']}'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Savings Configuration'),
          _buildIntervalDropdown(),
          const SizedBox(height: 16),
          _buildNumberField(
            label: 'Minimum Saving Per Interval (KES)',
            value: _minSaving,
            onChanged: (val) => setState(() => _minSaving = val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Penalty Rules'),
          SwitchListTile(
            title: const Text('Enable Automated Penalties'),
            subtitle: const Text('If minimum saving is not met for the period'),
            value: _penaltyEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _penaltyEnabled = val),
          ),
          if (_penaltyEnabled) ...[
            const SizedBox(height: 8),
            _buildNumberField(
              label: 'Penalty Amount (KES)',
              value: _penaltyAmount,
              onChanged: (val) => setState(() => _penaltyAmount = val),
            ),
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Group Settings',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Savings Interval',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _interval,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                DropdownMenuItem(value: 'BIWEEKLY', child: Text('Bi-Weekly')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
              ],
              onChanged: (val) => setState(() => _interval = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(
      {required String label,
      required double value,
      required Function(double) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value.toStringAsFixed(0)),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixText: 'KES ',
          ),
          onChanged: (val) {
            final parsed = double.tryParse(val);
            if (parsed != null) onChanged(parsed);
          },
        ),
      ],
    );
  }

  void _saveSettings() async {
    setState(() => _isSaving = true);
    final financeVm = context.read<FinanceViewModel>();
    final success = await financeVm.updateGroupSettings(widget.group['id'], {
      'savings_interval': _interval,
      'min_saving_amount': _minSaving,
      'penalty_amount': _penaltyAmount,
      'is_penalty_enabled': _penaltyEnabled,
    });

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
        Navigator.pop(context);
        // Refresh groups
        context.read<GovernanceViewModel>().fetchGroups();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update settings'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
