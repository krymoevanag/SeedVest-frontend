import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../data/models/user.dart';
import '../../core/network/api_service.dart';
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
    final canManageMembers = context.read<UserViewModel>().isAdmin ||
        context.read<UserViewModel>().isTreasurer;
    final usersNeedingGroups = viewModel.approvedUsers
        .where((user) => user.groupIds.isEmpty)
        .length;
    final users = viewModel.approvedUsers.where((user) {
      final name = user.fullName.toLowerCase();
      final email = user.email.toLowerCase();
      final role = user.role.toLowerCase();
      final groupNames = user.groupIds.map((id) {
        final group = viewModel.groups.firstWhere(
          (g) => g['id'] == id,
          orElse: () => null,
        );
        return group?['name']?.toString().toLowerCase() ?? '';
      }).join(' ');
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          role.contains(query) ||
          groupNames.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Member & Group Management')),
      body: Column(
        children: [
          if (canManageMembers)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildGroupAssignmentCallout(usersNeedingGroups),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members, roles, or groups...',
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
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Balance: ${_currencyFormat.format(balance)}',
                                        style: TextStyle(
                                          color: balance < 0
                                              ? Colors.red
                                              : Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (user.groupIds.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Groups: ${user.groupIds.map((id) {
                                              final group = viewModel.groups
                                                  .firstWhere(
                                                      (g) => g['id'] == id,
                                                      orElse: () => null);
                                              return group != null
                                                  ? group['name']
                                                  : 'ID: $id';
                                            }).join(", ")}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600]),
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            canManageMembers
                                                ? 'Needs group assignment'
                                                : 'No groups assigned yet',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange.shade800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.1),
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
                                          if (canManageMembers) Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _buildActionButton(
                                                icon: Icons.add_circle_outline,
                                                label: "Contrib",
                                                onPressed: () =>
                                                    _showAddContributionDialog(
                                                        context, user),
                                                color: Colors.green,
                                              ),
                                              _buildActionButton(
                                                icon: Icons.edit_outlined,
                                                label: "Role",
                                                onPressed: () =>
                                                    _showRoleDialog(
                                                        context, user),
                                              ),
                                              _buildActionButton(
                                                icon: Icons.gavel_outlined,
                                                label: "Penalty",
                                                onPressed: () =>
                                                    _showPenaltyDialog(
                                                        context, user),
                                                color: Colors.red,
                                              ),
                                              _buildActionButton(
                                                icon: Icons
                                                    .delete_forever_outlined,
                                                label: "Delete",
                                                onPressed: () =>
                                                    _showConfirmDeleteDialog(
                                                        context, user),
                                                color: Colors.red.shade900,
                                              ),
                                              _buildActionButton(
                                                icon: Icons.lock_reset_outlined,
                                                label: "Password",
                                                onPressed: () =>
                                                    _showAdminPasswordResetDialog(
                                                        context, user),
                                                color: AppColors.primary,
                                              ),
                                              _buildActionButton(
                                                icon: Icons.archive_outlined,
                                                label: "Archive Fin",
                                                onPressed: () =>
                                                    _showResetDialog(
                                                        context, user),
                                                color: Colors.orange.shade900,
                                              ),
                                              _buildActionButton(
                                                icon: Icons.group_add_outlined,
                                                label: user.groupIds.isEmpty
                                                    ? "Assign Group"
                                                    : "Manage Groups",
                                                onPressed: () =>
                                                    _showMemberGroupsDialog(
                                                        context, user),
                                              ),
                                            ],
                                          ) else const Center(
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8.0),
                                              child: Text(
                                                "Read-only access for Financial Secretary",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
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

  void _showAddContributionDialog(BuildContext context, User user) {
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    int? selectedGroupId;
    bool isSubmitting = false;

    // Filter groups for this user
    final viewModel = context.read<GovernanceViewModel>();
    final userGroups =
        viewModel.groups.where((g) => user.groupIds.contains(g['id'])).toList();

    if (userGroups.length == 1) {
      selectedGroupId = userGroups.first['id'];
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add Contribution for ${user.fullName}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Group:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (userGroups.isEmpty)
                      const Text('User is not assigned to any groups.',
                          style: TextStyle(color: Colors.red))
                    else
                      Wrap(
                        spacing: 8,
                        children: userGroups.map((g) {
                          final isSelected = selectedGroupId == g['id'];
                          return ChoiceChip(
                            label: Text(g['name'] ?? 'Group ${g['id']}'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setDialogState(() {
                                selectedGroupId = selected ? g['id'] : null;
                              });
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (KES)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedGroupId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a group')),
                            );
                            return;
                          }
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a valid amount')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          // Use ContributionsViewModel to add contribution
                          final contribViewModel =
                              context.read<ContributionsViewModel>();
                          final errorMessage =
                              await contribViewModel.adminAddContribution(
                            userId: user.id,
                            groupId: selectedGroupId!,
                            amount: amount,
                            paidDate:
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (context.mounted) {
                            // Refresh the member view to show new balance
                            context
                                .read<GovernanceViewModel>()
                                .fetchApprovedUsers();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage == null
                                    ? 'Contribution added successfully!'
                                    : 'Failed: $errorMessage'),
                                backgroundColor: errorMessage == null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildGroupAssignmentCallout(int usersNeedingGroups) {
    final hasUnassignedMembers = usersNeedingGroups > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasUnassignedMembers
            ? Colors.orange.shade50
            : AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasUnassignedMembers
              ? Colors.orange.shade200
              : AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasUnassignedMembers
                ? Icons.group_add_outlined
                : Icons.check_circle_outline,
            color: hasUnassignedMembers
                ? Colors.orange.shade800
                : AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnassignedMembers
                      ? '$usersNeedingGroups member(s) still need a group'
                      : 'All approved members already have a group',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  hasUnassignedMembers
                      ? 'Open a member card and tap Assign Group to place that member in a group and choose their role.'
                      : 'Use Manage Groups on any member card to update memberships or move members between groups.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  RadioGroup<String>(
                    groupValue: selectedRole,
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: const Text('Admin'),
                          subtitle: const Text('Full dashboard access'),
                          value: 'ADMIN',
                        ),
                        RadioListTile<String>(
                          title: const Text('Financial Secretary'),
                          subtitle: const Text('Financial oversight access'),
                          value: 'FINANCIAL_SECRETARY',
                        ),
                        RadioListTile<String>(
                          title: const Text('Treasurer'),
                          subtitle: const Text('Financial management access'),
                          value: 'TREASURER',
                        ),
                        RadioListTile<String>(
                          title: const Text('Member'),
                          subtitle: const Text('Standard user access'),
                          value: 'MEMBER',
                        ),
                      ],
                    ),
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
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(this.context);
                          final success =
                              await viewModel.updateRole(user.id, selectedRole);
                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
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
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Amount is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason',
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Reason is required'
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final messenger = ScaffoldMessenger.of(this.context);
                          final amountText =
                              amountController.text.replaceAll(',', '');
                          final amount = double.tryParse(amountText);
                          if (amount == null) {
                            messenger.showSnackBar(
                              const SnackBar(
                                  content: Text('Invalid amount'),
                                  backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final viewModel = context.read<GovernanceViewModel>();
                          final navigator = Navigator.of(context);
                          final success = await viewModel.issuePenalty(
                            userId: user.id,
                            amount: amount,
                            reason: reasonController.text,
                          );

                          if (mounted) {
                            if (navigator.canPop()) {
                              navigator.pop();
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Penalty issued successfully'
                                    : 'Failed to issue penalty'),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Issue Penalty'),
                ),
              ],
            );
          },
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);
                final success = await viewModel.deleteUser(user.id);

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Refresh Finance: ${user.fullName}'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will archive the member’s financial records from active balances, including contributions and penalties.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'The member account, profile, identity, and group memberships will remain intact.',
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
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(this.context);
                final success = await viewModel.resetFinanceHistory(
                  user.id,
                  false,
                );

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Financial records archived successfully'
                          : 'Failed to refresh financial records'),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
              ),
              child: const Text('Archive Records'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchUserMemberships(int userId) async {
    final apiService = ApiService();
    final response = await apiService.getMemberships();
    if (response.statusCode != 200 || response.data is! List) {
      return [];
    }
    return (response.data as List)
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) => item['user'] == userId)
        .toList();
  }

  void _showMemberGroupsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${user.fullName} - Groups'),
          content: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchUserMemberships(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  width: 320,
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SizedBox(
                  width: 320,
                  child: Text(
                    'Failed to load member groups.',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final memberships = snapshot.data ?? [];
              if (memberships.isEmpty) {
                return const SizedBox(
                  width: 320,
                  child: Text(
                    'This member is not assigned to any group yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return SizedBox(
                width: 320,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: memberships.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final membership = memberships[index];
                    final role = (membership['role'] ?? 'MEMBER').toString();
                    final joinedAt = DateTime.tryParse(
                      membership['joined_at']?.toString() ?? '',
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.groups_2_outlined),
                      title: Text(
                        membership['group_name']?.toString() ??
                            'Group ${membership['group']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        joinedAt == null
                            ? 'Role: $role'
                            : 'Role: $role - Joined ${DateFormat('dd MMM yyyy').format(joinedAt)}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _showEditMembershipRoleDialog(
                              context,
                              membership['id'],
                              membership['group_name'] ?? 'Group',
                              role,
                            ),
                            tooltip: 'Edit Role',
                          ),
                          IconButton(
                            icon: const Icon(Icons.group_remove_outlined,
                                size: 20, color: Colors.red),
                            onPressed: () => _showRemoveFromGroupDialog(
                              context,
                              membership['id'],
                              membership['group_name'] ?? 'Group',
                              user.fullName,
                            ),
                            tooltip: 'Remove from Group',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAssignGroupDialogWithExisting(
                  context,
                  user,
                  existingGroupIds: user.groupIds,
                );
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Assign Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAssignGroupDialogWithExisting(
    BuildContext context,
    User user, {
    List<int> existingGroupIds = const [],
  }) {
    int? selectedGroupId;
    String selectedRole = 'MEMBER';
    bool isSubmitting = false;

    final viewModel = context.read<GovernanceViewModel>();
    final availableGroups = viewModel.groups
        .where((g) => !existingGroupIds.contains(g['id']))
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Assign ${user.fullName} to Group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Group:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (availableGroups.isEmpty)
                    Text(
                      'This member is already assigned to all available groups.',
                      style: TextStyle(color: Colors.grey[700]),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: selectedGroupId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: availableGroups.map<DropdownMenuItem<int>>((g) {
                        return DropdownMenuItem<int>(
                          value: g['id'],
                          child: Text(g['name'] ?? 'Group ${g['id']}'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setDialogState(() => selectedGroupId = val),
                    ),
                  const SizedBox(height: 16),
                  const Text('Select Role:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                      DropdownMenuItem(
                          value: 'TREASURER', child: Text('Treasurer')),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ||
                          selectedGroupId == null ||
                          availableGroups.isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);

                          final success = await viewModel.assignUserToGroup(
                            userId: user.id,
                            groupId: selectedGroupId!,
                            role: selectedRole,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Member assigned to group successfully!'
                                    : 'Failed to assign member to group'),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Assign',
                          style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMembershipRoleDialog(
      BuildContext context, int membershipId, String groupName, String currentRole) {
    String selectedRole = currentRole;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Role in $groupName'),
              content: DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Select Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                  DropdownMenuItem(value: 'TREASURER', child: Text('Treasurer')),
                ],
                onChanged: (val) => setDialogState(() => selectedRole = val!),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting || selectedRole == currentRole
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final success = await context
                              .read<GovernanceViewModel>()
                              .updateMembershipRole(membershipId, selectedRole);

                          if (dialogContext.mounted) Navigator.pop(dialogContext);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Role updated successfully!'
                                    : 'Failed to update role'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRemoveFromGroupDialog(
      BuildContext context, int membershipId, String groupName, String userName) {
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Remove from Group'),
              content: Text('Are you sure you want to remove $userName from $groupName? '
                  'Historical contributions will be preserved but the member will no longer be active in this group.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          final success = await context
                              .read<GovernanceViewModel>()
                              .removeFromGroup(membershipId);

                          if (dialogContext.mounted) Navigator.pop(dialogContext);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Member removed from group successfully!'
                                    : 'Failed to remove member'),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Remove', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdminPasswordResetDialog(BuildContext context, User user) {
    final customPasswordController = TextEditingController();
    bool useCustomPassword = false;
    bool isSubmitting = false;
    final hasEmail = user.email.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.lock_reset, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password & Access: ${user.fullName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasEmail && !user.isActive) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Pending Setup',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'An account setup email link can be resent to ${user.email}.',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.mark_email_read_outlined,
                                  size: 16),
                              label: const Text('Resend Setup Email'),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setDialogState(() => isSubmitting = true);
                                      final result = await context
                                          .read<GovernanceViewModel>()
                                          .resendSetupLink(user.id);
                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              result != null
                                                  ? (result['message'] ??
                                                      'Setup email sent!')
                                                  : 'Failed to send setup email.',
                                            ),
                                            backgroundColor: result != null
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Admin Direct Password Reset',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sets a new temporary password for ${user.fullName} instantly. The account will be marked active.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set custom password',
                          style: TextStyle(fontSize: 14)),
                      subtitle: const Text('Otherwise auto-generates a password',
                          style: TextStyle(fontSize: 12)),
                      value: useCustomPassword,
                      onChanged: (val) =>
                          setDialogState(() => useCustomPassword = val),
                    ),
                    if (useCustomPassword) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Temporary Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.key),
                          hintText: 'Minimum 8 characters',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final pass = customPasswordController.text.trim();
                          if (useCustomPassword && pass.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Custom password must be at least 8 characters'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final result = await context
                              .read<GovernanceViewModel>()
                              .adminResetPassword(
                                user.id,
                                newPassword:
                                    useCustomPassword ? pass : null,
                              );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (context.mounted) {
                            if (result != null &&
                                result['credentials'] != null) {
                              _showCredentialsSummaryModal(
                                context,
                                Map<String, dynamic>.from(
                                  result['credentials'] as Map,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result?['detail'] ??
                                        'Password reset successfully!',
                                  ),
                                  backgroundColor: result != null
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCredentialsSummaryModal(
      BuildContext context, Map<String, dynamic> creds) {
    final name = creds['name'] ?? 'Member';
    final membershipNo = creds['membership_number'] ?? '';
    final phone = creds['phone_number'] ?? '';
    final password = creds['initial_password'] ?? '';

    final shareText = '''
SeedVest Member Access Restored
Name: $name
Membership No: $membershipNo
Login Phone: $phone
Temporary Password: $password

Please log in and update your password upon signing in.
''';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Credentials Generated'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password reset successfully! You can copy these credentials to send via SMS or WhatsApp:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member: $name',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Membership No: $membershipNo'),
                  const SizedBox(height: 4),
                  Text('Login Phone: $phone'),
                  const SizedBox(height: 4),
                  SelectableText(
                    'Temporary Password: $password',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('COPY CREDENTIALS'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Credentials copied to clipboard!')),
              );
            },
          ),
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }
}

