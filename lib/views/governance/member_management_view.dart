import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_card.dart';

import 'package:intl/intl.dart';

class MemberManagementView extends StatefulWidget {
  const MemberManagementView({super.key});

  @override
  State<MemberManagementView> createState() => _MemberManagementViewState();
}

class _MemberManagementViewState extends State<MemberManagementView> {
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: 'KES ');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernanceViewModel>().fetchApprovedUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();
    final users = viewModel.approvedUsers.where((user) {
      final name = user.fullName.toLowerCase();
      final email = user.email.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Member Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: viewModel.isLoading && viewModel.approvedUsers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No members found'
                              : 'No results for "$_searchQuery"',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: viewModel.fetchApprovedUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            final balance =
                                user.totalSavings - user.totalPenalties;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: CustomCard(
                                child: ExpansionTile(
                                  title: Text(
                                    user.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Balance: ${_currencyFormat.format(balance)}',
                                    style: TextStyle(
                                      color: balance < 0
                                          ? Colors.red
                                          : Colors.green[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.1),
                                    backgroundImage: user.profilePicture != null
                                        ? NetworkImage(user.profilePicture!)
                                        : null,
                                    child: user.profilePicture == null
                                        ? Text(user.fullName.isEmpty
                                            ? '?'
                                            : user.fullName.substring(0, 1))
                                        : null,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          _buildFinanceRow('Total Savings',
                                              user.totalSavings, Colors.green),
                                          const SizedBox(height: 8),
                                          _buildFinanceRow('Total Penalties',
                                              user.totalPenalties, Colors.red),
                                          const Divider(height: 24),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildActionButton(
                                                icon: Icons.edit_outlined,
                                                label: 'Role',
                                                onPressed: () =>
                                                    _showRoleDialog(
                                                        context, user),
                                              ),
                                              _buildActionButton(
                                                icon: Icons.gavel_outlined,
                                                label: 'Penalty',
                                                onPressed: () =>
                                                    _showPenaltyDialog(
                                                        context, user),
                                                color: Colors.red,
                                              ),
                                              _buildActionButton(
                                                icon: Icons
                                                    .delete_forever_outlined,
                                                label: 'Delete',
                                                onPressed: () =>
                                                    _showConfirmDeleteDialog(
                                                        context, user),
                                                color: Colors.red.shade900,
                                              ),
                                              _buildActionButton(
                                                icon: Icons.refresh_outlined,
                                                label: 'Reset',
                                                onPressed: () =>
                                                    _showResetDialog(
                                                        context, user),
                                                color: Colors.orange.shade800,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600])),
        Text(
          _currencyFormat.format(amount),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = AppColors.primary,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      label: Text(label, style: TextStyle(color: color)),
    );
  }

  void _showRoleDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Update Role for ${user.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Admin'),
                    subtitle: const Text('Full dashboard access'),
                    value: 'ADMIN',
                    groupValue: selectedRole,
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Treasurer'),
                    subtitle: const Text('Financial management access'),
                    value: 'TREASURER',
                    groupValue: selectedRole,
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Member'),
                    subtitle: const Text('Standard user access'),
                    value: 'MEMBER',
                    groupValue: selectedRole,
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: user.role == selectedRole
                      ? null
                      : () async {
                          final viewModel = context.read<GovernanceViewModel>();
                          final success =
                              await viewModel.updateRole(user.id, selectedRole);
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Role updated successfully'
                                    : 'Failed to update role'),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPenaltyDialog(BuildContext context, dynamic user) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Issue Penalty to ${user.fullName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (KES)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Amount is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Reason is required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final viewModel = context.read<GovernanceViewModel>();
                final success = await viewModel.issuePenalty(
                  userId: user.id,
                  amount: double.parse(amountController.text),
                  reason: reasonController.text,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Penalty issued successfully'
                          : 'Failed to issue penalty'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Issue Penalty'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteDialog(BuildContext context, dynamic user) {
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('DELETE MEMBER: ${user.fullName}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'CAUTION: This action is permanent and will delete all user data.',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                    'To confirm, please type the member\'s email: ${user.email}'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val != user.email) {
                      return 'Email does not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final viewModel = context.read<GovernanceViewModel>();
                final success = await viewModel.deleteUser(user.id);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Member deleted successfully'
                          : 'Failed to delete member'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
              ),
              child: const Text('DELETE PERMANENTLY',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, dynamic user) {
    bool resetStatus = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Reset Finance: ${user.fullName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will clear all contributions and penalties for this member. This action cannot be undone.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Reset Account Status'),
                    subtitle: const Text('Move back to Under Review'),
                    value: resetStatus,
                    onChanged: (val) =>
                        setDialogState(() => resetStatus = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final viewModel = context.read<GovernanceViewModel>();
                    final success = await viewModel.resetFinanceHistory(
                      user.id,
                      resetStatus,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Financial history reset successfully'
                              : 'Failed to reset history'),
                          backgroundColor:
                              success ? AppColors.success : AppColors.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800,
                  ),
                  child: const Text('Confirm Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
