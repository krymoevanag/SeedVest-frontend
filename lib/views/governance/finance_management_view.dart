import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_card.dart';

class FinanceManagementView extends StatelessWidget {
  const FinanceManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _ManagementOptionCard(
              title: 'Record Group Payment',
              description: 'Manually record a payment made outside the system.',
              icon: Icons.add_card_outlined,
              color: AppColors.primary,
              onTap: () {
                // TODO: Open Record Payment Modal
              },
            ),
            const SizedBox(height: 16),
            _ManagementOptionCard(
              title: 'Issue Penalty',
              description: 'Assign a new fine to a member for rules violation.',
              icon: Icons.gavel_outlined,
              color: AppColors.error,
              onTap: () {
                // TODO: Open Issue Penalty Modal
              },
            ),
            const SizedBox(height: 16),
            _ManagementOptionCard(
              title: 'Manage Investments',
              description: 'Create and track group investment opportunities.',
              icon: Icons.trending_up,
              color: AppColors.accent,
              onTap: () {
                // TODO: Navigate to Investment Management
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
