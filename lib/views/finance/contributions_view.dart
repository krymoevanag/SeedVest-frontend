import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionsViewModel>().fetchContributions();
    });
  }

  void _showPaymentModal(BuildContext context) {
    final amountController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Make a Contribution',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Enter the amount and your M-Pesa phone number.'),
              const SizedBox(height: 24),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (KES)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'M-Pesa Phone Number',
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: '2547XXXXXXXX',
                ),
                validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Initiate M-Pesa Payment',
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final viewModel = context.read<ContributionsViewModel>();
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Initiating STK Push... Check your phone.')),
                    );

                    bool success = await viewModel.initiatePayment(
                      double.parse(amountController.text),
                      phoneController.text,
                    );

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment request sent!')),
                      );
                      viewModel.fetchContributions();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to initiate payment.')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(title: const Text('My Contributions')),
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
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.account_balance_wallet, color: AppColors.primary),
                        ),
                        title: Text(
                          currencyFormat.format(contribution.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(DateFormat('MMM dd, yyyy - HH:mm').format(contribution.date)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: contribution.status == 'SUCCESS' 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            contribution.status,
                            style: TextStyle(
                              color: contribution.status == 'SUCCESS' ? Colors.green : Colors.orange,
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
