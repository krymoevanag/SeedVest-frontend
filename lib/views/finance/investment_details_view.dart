import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/colors.dart';
import '../../data/models/investment.dart';
import '../widgets/custom_card.dart';

class InvestmentDetailsView extends StatelessWidget {
  final Investment investment;

  const InvestmentDetailsView({super.key, required this.investment});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');
    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Investment Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investment.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Created on ${dateFormat.format(investment.date)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomCard(
              color: AppColors.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DetailStat(
                    label: 'Total Principal',
                    value: currencyFormat.format(investment.amount),
                    color: Colors.white,
                  ),
                  _DetailStat(
                    label: 'Expected ROI',
                    value: '${investment.expectedRoi}%',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              investment.description,
              style: const TextStyle(height: 1.6, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Text(
              'Performance Tracking',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                children: [
                   _PerformanceRow(label: 'Status', value: investment.status, isStatus: true),
                   const Divider(),
                   _PerformanceRow(label: 'Initial Value', value: currencyFormat.format(investment.amount)),
                   const Divider(),
                   _PerformanceRow(
                     label: 'Projected Returns', 
                     value: currencyFormat.format(investment.amount * (1 + investment.expectedRoi / 100)),
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

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isStatus;

  const _PerformanceRow({required this.label, required this.value, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus ? (value == 'ACTIVE' ? Colors.green : Colors.blue) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
