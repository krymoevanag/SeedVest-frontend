import 'package:flutter/material.dart';
import '../finance/investments_view.dart';
import '../widgets/add_investment_dialog.dart';

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

  void _showAddInvestmentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddInvestmentDialog(),
    );

    if (result == true && mounted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Investment created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
