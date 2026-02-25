import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class ContributionsView extends StatefulWidget {
  const ContributionsView({super.key});

  @override
  State<ContributionsView> createState() => _ContributionsViewState();
}

class _ContributionsViewState extends State<ContributionsView> {
  static const String _methodMpesa = 'mpesa';
  static const String _methodKcb = 'kcb';
  static const String _methodEquity = 'equity';
  static const String _methodCoop = 'coop';
  static const String _methodAbsa = 'absa';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionsViewModel>().fetchContributions();
    });
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
        return 'BANK_TRANSFER';
      default:
        return 'OTHER';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PAID':
      case 'LATE':
      case 'SUCCESS':
        return Colors.green;
      case 'REJECTED':
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<List<Map<String, dynamic>>> _loadAvailableGroups() async {
    try {
      final response = await ApiService().getGroups();
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Widget _buildMethodCard({
    required String id,
    required String selected,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final isSelected = selected == id;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade300,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPaymentModal(BuildContext context) async {
    final groups = await _loadAvailableGroups();
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final referenceController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedMethod = _methodMpesa;
    DateTime reportedPaidDate = DateTime.now();
    int? selectedGroupId = groups.length == 1 ? groups.first['id'] as int? : null;

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isManualProposal = selectedMethod != _methodMpesa;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Make a Contribution',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Pay with M-Pesa or submit an external payment proposal.'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildMethodCard(
                          id: _methodMpesa,
                          selected: selectedMethod,
                          label: 'M-Pesa',
                          subtitle: 'STK Push',
                          icon: Icons.sim_card,
                          accentColor: const Color(0xFF2E7D32),
                          onTap: () => setSheetState(() {
                            selectedMethod = _methodMpesa;
                          }),
                        ),
                        const SizedBox(width: 10),
                        _buildMethodCard(
                          id: _methodKcb,
                          selected: selectedMethod,
                          label: 'KCB',
                          subtitle: 'Manual',
                          icon: Icons.account_balance,
                          accentColor: const Color(0xFF0D47A1),
                          onTap: () => setSheetState(() {
                            selectedMethod = _methodKcb;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMethodCard(
                          id: _methodEquity,
                          selected: selectedMethod,
                          label: 'Equity',
                          subtitle: 'Manual',
                          icon: Icons.account_balance,
                          accentColor: const Color(0xFF8E24AA),
                          onTap: () => setSheetState(() {
                            selectedMethod = _methodEquity;
                          }),
                        ),
                        const SizedBox(width: 10),
                        _buildMethodCard(
                          id: _methodCoop,
                          selected: selectedMethod,
                          label: 'Co-op',
                          subtitle: 'Manual',
                          icon: Icons.account_balance,
                          accentColor: const Color(0xFFF57C00),
                          onTap: () => setSheetState(() {
                            selectedMethod = _methodCoop;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMethodCard(
                          id: _methodAbsa,
                          selected: selectedMethod,
                          label: 'Absa',
                          subtitle: 'Manual',
                          icon: Icons.account_balance,
                          accentColor: const Color(0xFFC62828),
                          onTap: () => setSheetState(() {
                            selectedMethod = _methodAbsa;
                          }),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                    if (!isManualProposal) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
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
                      const SizedBox(height: 16),
                      if (groups.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: selectedGroupId,
                          decoration: const InputDecoration(
                            labelText: 'Group',
                            prefixIcon: Icon(Icons.group),
                          ),
                          hint: const Text('Select group'),
                          items: groups.map((g) {
                            return DropdownMenuItem<int>(
                              value: g['id'] as int,
                              child: Text(g['name'] ?? 'Group ${g['id']}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setSheetState(() => selectedGroupId = value);
                          },
                        ),
                      if (groups.isNotEmpty) const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: reportedPaidDate,
                            firstDate:
                                DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setSheetState(() => reportedPaidDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Reported Payment Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(reportedPaidDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: referenceController,
                        decoration: const InputDecoration(
                          labelText: 'Reference (optional)',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes for admin (optional)',
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
                          'This ${_paymentMethodName(selectedMethod)} payment will be submitted as a pending proposal for admin verification.',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    CustomButton(
                      text: isManualProposal
                          ? 'Submit for Verification'
                          : 'Push M-Pesa STK',
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final viewModel = this.context.read<ContributionsViewModel>();
                        final messenger = ScaffoldMessenger.of(this.context);
                        final amount = double.parse(amountController.text.trim());
                        if (isManualProposal &&
                            groups.length > 1 &&
                            selectedGroupId == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Please select a group first.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        Navigator.pop(context);

                        if (!isManualProposal) {
                          final phone =
                              _normalizeMpesaPhone(phoneController.text.trim());
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Initiating M-Pesa STK Push. Check your phone.',
                              ),
                            ),
                          );

                          final success = await viewModel.initiatePayment(
                            amount,
                            phone,
                          );

                          if (!mounted) return;
                          if (success) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('M-Pesa push sent successfully.'),
                              ),
                            );
                            viewModel.fetchContributions();
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to initiate M-Pesa push.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }

                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Submitting contribution proposal for admin verification.',
                            ),
                          ),
                        );

                        final success = await viewModel.proposeManualContribution(
                          groupId: selectedGroupId,
                          amount: amount,
                          reportedPaidDate: reportedPaidDate,
                          paymentMethod: _backendManualMethod(selectedMethod),
                          reference: referenceController.text,
                          note: noteController.text,
                        );

                        if (!mounted) return;
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Proposal submitted. It is now pending approval.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Failed to submit proposal. Select a group and try again.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: viewModel.fetchContributions,
        child: viewModel.isLoading && viewModel.contributions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: viewModel.contributions.length,
                itemBuilder: (context, index) {
                  final contribution = viewModel.contributions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        ),
                        title: Text(
                          currencyFormat.format(contribution.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          contribution.isManualEntry
                              ? '${DateFormat('MMM dd, yyyy - HH:mm').format(contribution.date)} - Manual proposal'
                              : DateFormat('MMM dd, yyyy - HH:mm')
                                  .format(contribution.date),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(contribution.status)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            contribution.status,
                            style: TextStyle(
                              color: _statusColor(contribution.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentModal(context),
        label: const Text('New Contribution'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
