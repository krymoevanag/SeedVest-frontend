import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';

class CloseCycleDialog extends StatefulWidget {
  final int cycleId;
  final String? currentCycleName;

  const CloseCycleDialog({
    super.key,
    required this.cycleId,
    this.currentCycleName,
  });

  @override
  State<CloseCycleDialog> createState() => _CloseCycleDialogState();
}

class _CloseCycleDialogState extends State<CloseCycleDialog> {
  final _cycleNameController = TextEditingController();

  bool _carryForwardContributions = false;
  bool _carryForwardMissed = false;
  bool _carryForwardLoans = false;
  bool _createNewCycle = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cycleNameController.dispose();
    super.dispose();
  }

  void _onToggleContributions(bool value) {
    setState(() {
      _carryForwardContributions = value;
      if (value) {
        // Mutual exclusion: only one contribution rollover mode allowed
        _carryForwardMissed = false;
      }
    });
  }

  void _onToggleMissed(bool value) {
    setState(() {
      _carryForwardMissed = value;
      if (value) {
        // Mutual exclusion: only one contribution rollover mode allowed
        _carryForwardContributions = false;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final viewModel = context.read<GovernanceViewModel>();
      final result = await viewModel.closeCycle(
        widget.cycleId,
        carryForwardContributions: _carryForwardContributions,
        carryForwardMissed: _carryForwardMissed,
        carryForwardLoans: _carryForwardLoans,
        createNewCycle: _createNewCycle,
        cycleName: _cycleNameController.text.trim(),
      );

      if (!mounted) return;

      if (result != null) {
        final summary = result['rollover_summary'] as Map<String, dynamic>? ?? {};
        final contributionsRolled = summary['contributions_rolled'] ?? 0;
        final missedRolled = summary['missed_rolled'] ?? 0;
        final loansRelinked = summary['loans_relinked'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cycle closed successfully! '
              'Rolled: $contributionsRolled pending, $missedRolled overdue, $loansRelinked loans relinked.',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(result);
      } else {
        final errorMsg = viewModel.closureError ?? 'Failed to close financial cycle.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.archive_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Close Financial Cycle'),
            ],
          ),
          if (widget.currentCycleName != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.currentCycleName!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Superusers can carry forward deficits and active loans into the new cycle. '
                        'Contribution rollover modes are mutually exclusive.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade900,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Switch 1: Carry Forward Contributions
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Carry Forward Contributions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Recreate outstanding balances as PENDING contributions in the new cycle.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _carryForwardContributions,
                onChanged: _isSubmitting ? null : _onToggleContributions,
              ),
              const Divider(height: 1),

              // Switch 2: Carry Forward Missed Payments
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Carry Forward Missed Payments',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Recreate partial or missed months as OVERDUE contributions in the new cycle.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _carryForwardMissed,
                onChanged: _isSubmitting ? null : _onToggleMissed,
              ),
              const Divider(height: 1),

              // Switch 3: Carry Forward Loans
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Carry Forward Active Loans',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Re-link active loans with remaining balance to the new cycle.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _carryForwardLoans,
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _carryForwardLoans = val),
              ),
              const Divider(height: 1),

              // Switch 4: Create Next Cycle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Create Next Cycle',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Automatically generate and activate the subsequent financial cycle.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _createNewCycle,
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _createNewCycle = val),
              ),
              const SizedBox(height: 12),

              if (_createNewCycle) ...[
                TextField(
                  controller: _cycleNameController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'New Cycle Name (Optional)',
                    hintText: 'e.g. 2027 Cycle',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Close Cycle'),
        ),
      ],
    );
  }
}
