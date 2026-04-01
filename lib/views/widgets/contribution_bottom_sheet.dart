import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../core/network/api_service.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import 'custom_button.dart';

class ContributionBottomSheet extends StatefulWidget {
  final VoidCallback? onSuccess;

  const ContributionBottomSheet({super.key, this.onSuccess});

  @override
  State<ContributionBottomSheet> createState() =>
      _ContributionBottomSheetState();
}

class _ContributionBottomSheetState extends State<ContributionBottomSheet> {
  static const String _methodMpesa = 'mpesa';
  static const String _methodKcb = 'kcb';
  static const String _methodEquity = 'equity';
  static const String _methodCoop = 'coop';
  static const String _methodAbsa = 'absa';
  static const String _methodManual = 'manual';

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedMethod = _methodMpesa;
  DateTime _reportedPaidDate = DateTime.now();
  int? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoadingGroups = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await ApiService().getGroups();
      if (response.statusCode == 200 && response.data is List) {
        if (mounted) {
          setState(() {
            _groups = (response.data as List)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            if (_groups.length == 1) {
              _selectedGroupId = _groups.first['id'] as int?;
            }
            _isLoadingGroups = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingGroups = false);
      }
    }
  }

  String _normalizeMpesaPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      return '254${clean.substring(1)}';
    }
    if (clean.startsWith('+254')) {
      return clean.substring(1);
    }
    return clean;
  }

  String _paymentMethodName(String method) {
    switch (method) {
      case _methodMpesa:
        return 'M-Pesa';
      case _methodKcb:
        return 'KCB Bank';
      case _methodEquity:
        return 'Equity Bank';
      case _methodCoop:
        return 'Co-operative Bank';
      case _methodAbsa:
        return 'Absa Bank';
      case _methodManual:
        return 'Manual Bank';
      default:
        return 'Payment Method';
    }
  }

  String _backendManualMethod(String method) {
    switch (method) {
      case _methodMpesa:
        return 'M_PESA';
      case _methodKcb:
      case _methodEquity:
      case _methodCoop:
      case _methodAbsa:
      case _methodManual:
        return 'BANK_TRANSFER';
      default:
        return 'OTHER';
    }
  }

  Widget _buildMethodCard({
    required String id,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    bool comingSoon = false,
  }) {
    final isSelected = _selectedMethod == id;
    final isDisabled = comingSoon;

    return Expanded(
      child: GestureDetector(
        onTap: isDisabled ? null : () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : (isDisabled ? Colors.grey.shade50 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDisabled ? Colors.grey.shade200 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon,
                      color: isDisabled ? Colors.grey : accentColor, size: 22),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDisabled ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (comingSoon)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Text(
                      'SOON',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final isManualProposal = _selectedMethod != _methodMpesa;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contribution',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Pay with M-Pesa or submit an external payment proposal.'),
              const SizedBox(height: 20),

              // Payment Methods
              Row(
                children: [
                  _buildMethodCard(
                    id: _methodMpesa,
                    label: 'M-Pesa',
                    subtitle: 'STK Push',
                    icon: Icons.sim_card,
                    accentColor: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 10),
                  _buildMethodCard(
                    id: _methodManual,
                    label: 'Manual Bank',
                    subtitle: 'Reference',
                    icon: Icons.account_balance,
                    accentColor: Colors.blueGrey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMethodCard(
                    id: _methodKcb,
                    label: 'KCB',
                    subtitle: 'Manual',
                    icon: Icons.account_balance,
                    accentColor: const Color(0xFF0D47A1),
                    comingSoon: true,
                  ),
                  const SizedBox(width: 10),
                  _buildMethodCard(
                    id: _methodEquity,
                    label: 'Equity',
                    subtitle: 'Manual',
                    icon: Icons.account_balance,
                    accentColor: const Color(0xFF8E24AA),
                    comingSoon: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMethodCard(
                    id: _methodCoop,
                    label: 'Co-op',
                    subtitle: 'Manual',
                    icon: Icons.account_balance,
                    accentColor: const Color(0xFFF57C00),
                    comingSoon: true,
                  ),
                  const SizedBox(width: 10),
                  _buildMethodCard(
                    id: _methodAbsa,
                    label: 'Absa',
                    subtitle: 'Manual',
                    icon: Icons.account_balance,
                    accentColor: const Color(0xFFC62828),
                    comingSoon: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Amount Field
              TextFormField(
                controller: _amountController,
                enabled: !_isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (KES)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Group Selection (Always show if multiple groups, or if manual proposal)
              if (_isLoadingGroups)
                const Center(child: CircularProgressIndicator())
              else if (_groups.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(
                    labelText: 'Select Group',
                    prefixIcon: Icon(Icons.group),
                  ),
                  hint: const Text('Target Group'),
                  items: _groups.map((g) {
                    return DropdownMenuItem<int>(
                      value: g['id'] as int,
                      child: Text(g['name'] ?? 'Group ${g['id']}'),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedGroupId = value),
                  validator: (value) =>
                      value == null ? 'Please select a group' : null,
                ),

              if (_groups.isNotEmpty) const SizedBox(height: 16),

              if (!isManualProposal) ...[
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    prefixIcon: Icon(Icons.phone_android),
                    hintText: '2547XXXXXXXX or 07XXXXXXXX',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter phone number';
                    }
                    final normalized = _normalizeMpesaPhone(value.trim());
                    if (!RegExp(r'^2547\d{8}$').hasMatch(normalized)) {
                      return 'Use a valid Safaricom number';
                    }
                    return null;
                  },
                ),
              ] else ...[
                InkWell(
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _reportedPaidDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _reportedPaidDate = picked);
                          }
                        },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Reported Payment Date',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                        DateFormat('dd MMM yyyy').format(_reportedPaidDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referenceController,
                  enabled: !_isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Payment Reference',
                    prefixIcon: Icon(Icons.tag),
                    hintText: 'Enter bank transaction reference',
                  ),
                  validator: (value) {
                    if (isManualProposal &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Enter payment reference';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  enabled: !_isSubmitting,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'This ${_paymentMethodName(_selectedMethod)} payment will be submitted as a pending proposal for admin verification.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],

              if (_mpesaStatusMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _mpesaStatusMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: isManualProposal ? 'Submit Proposal' : 'Push M-Pesa STK',
                isLoading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String? _mpesaStatusMessage;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _mpesaStatusMessage = null;
    });

    final viewModel = context.read<ContributionsViewModel>();
    final dashboardViewModel = context.read<DashboardViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final amount = double.parse(_amountController.text.trim());

    if (_selectedMethod == _methodMpesa) {
      final phone = _normalizeMpesaPhone(_phoneController.text.trim());

      final checkoutId = await viewModel.initiatePayment(
        amount,
        phone,
        groupId: _selectedGroupId,
      );

      if (!mounted) {
        return;
      }
      if (checkoutId != null) {
        setState(() {
          _mpesaStatusMessage = 'Push initiated. Please check your phone...';
        });

        // Start polling for status
        await _pollMpesaStatus(checkoutId, viewModel, dashboardViewModel);
      } else {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                viewModel.paymentError ?? 'Failed to initiate M-Pesa push.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      final success = await viewModel.proposeManualContribution(
        groupId: _selectedGroupId,
        amount: amount,
        reportedPaidDate: _reportedPaidDate,
        paymentMethod: _backendManualMethod(_selectedMethod),
        reference: _referenceController.text,
        note: _noteController.text,
      );

      if (!mounted) {
        return;
      }
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Proposal submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData(viewModel, dashboardViewModel);
        Navigator.pop(context);
      } else {
        setState(() => _isSubmitting = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to submit proposal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pollMpesaStatus(
    String checkoutId,
    ContributionsViewModel viewModel,
    DashboardViewModel dashboardViewModel,
  ) async {
    int attempts = 0;
    const maxAttempts = 20; // 20 * 3s = 60s timeout
    final messenger = ScaffoldMessenger.of(context);

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) {
        return;
      }

      final status = await viewModel.checkMpesaPaymentStatus(checkoutId);

      if (!mounted) {
        return;
      }

      if (status == 'SUCCESS') {
        setState(() {
          _mpesaStatusMessage = 'Payment successful!';
        });
        _refreshData(viewModel, dashboardViewModel);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      } else if (status == 'FAILED') {
        setState(() {
          _isSubmitting = false;
          _mpesaStatusMessage = 'Payment failed or was cancelled.';
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('M-Pesa payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      attempts++;
      setState(() {
        _mpesaStatusMessage =
            'Waiting for confirmation... (${maxAttempts - attempts}s remaining)';
      });
    }

    // Timeout
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _mpesaStatusMessage =
            'Confirmation timed out. Please check your balance later.';
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Payment confirmation timed out.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _refreshData(ContributionsViewModel cvm, DashboardViewModel dvm) {
    cvm.fetchContributions();
    dvm.refreshStats();
    if (widget.onSuccess != null) widget.onSuccess!();
  }
}
