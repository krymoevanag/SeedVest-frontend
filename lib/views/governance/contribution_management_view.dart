import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/contributions_viewmodel.dart';
import '../../data/models/contribution.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_card.dart';

class ContributionManagementView extends StatefulWidget {
  const ContributionManagementView({super.key});

  @override
  State<ContributionManagementView> createState() =>
      _ContributionManagementViewState();
}

class _ContributionManagementViewState
    extends State<ContributionManagementView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ContributionsViewModel>();
      viewModel.fetchContributions();
      viewModel.fetchUsersAndGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    final memberById = <int, Map<String, dynamic>>{
      for (final member in viewModel.members)
        if (member['id'] is int) member['id'] as int: member,
    };
    // Filter to show active contributions (PENDING and PAID) for management
    final activeContributions = viewModel.contributions
        .where((c) => (c.status == 'PENDING' || c.status == 'PAID') && !c.isLocked)
        .toList();
    final currencyFormat = NumberFormat.currency(symbol: 'KES ');

    return Scaffold(
      appBar: AppBar(title: const Text('Contribution Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContributionDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Contribution',
            style: TextStyle(color: Colors.white)),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeContributions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No active contributions found',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.fetchContributions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeContributions.length,
                    itemBuilder: (context, index) {
                      final contribution = activeContributions[index];
                      final member = memberById[contribution.userId];
                      final memberName = ((member?['full_name'] ?? '')
                              .toString()
                              .trim()
                              .isNotEmpty)
                          ? (member?['full_name'] as String).trim()
                          : ((member?['email'] ?? 'Unknown member').toString());
                      final memberMembershipNumber =
                          (member?['membership_number'] ?? '')
                              .toString()
                              .trim();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomCard(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            memberName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (memberMembershipNumber.isNotEmpty)
                                            Text(
                                              'MBR#: $memberMembershipNumber',
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          currencyFormat
                                              .format(contribution.amount),
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          contribution.status,
                                          style: TextStyle(
                                            color: contribution.status == 'PAID'
                                              ? Colors.green
                                              : Colors.orange,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold
                                          )
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Submitted: ${DateFormat('dd MMM yyyy').format(contribution.date)}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                                if (contribution.isManualEntry) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Manual entry',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                if (contribution.status == 'PENDING')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _confirmAction(
                                              context, 'reject', contribution.id),
                                          style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _confirmAction(context,
                                              'approve', contribution.id),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary),
                                          child: const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (contribution.status == 'PAID')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showEditDialog(context, contribution),
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          label: const Text('Edit'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: const BorderSide(color: Colors.blue)
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _confirmAction(context, 'archive', contribution.id),
                                          icon: const Icon(Icons.archive_outlined, size: 18),
                                          label: const Text('Archive'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: const BorderSide(color: Colors.orange)
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showEditDialog(BuildContext context, Contribution contribution) {
    final amountController = TextEditingController(text: contribution.amount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Contribution"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Correction of logged amount. This will recalculate cycle totals."),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount (KES)",
                prefixText: "KES ",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(amountController.text);
              if (val == null || val <= 0) return;
              
              final vm = Provider.of<ContributionsViewModel>(context, listen: false);
              final success = await vm.updateContribution(contribution.id, {'amount': val});
              
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? "Updated successfully" : "Update failed"),
                    backgroundColor: success ? Colors.green : Colors.red,
                  )
                );
              }
            },
            child: const Text("Save Changes"),
          )
        ],
      ),
    );
  }

  void _confirmAction(BuildContext context, String action, int id) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${action[0].toUpperCase()}${action.substring(1)} Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to $action this contribution?'),
            if (action == 'reject' || action == 'archive') ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: action == 'reject' ? 'Rejection reason' : 'Reason for archiving',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if ((action == 'reject' || action == 'archive') && reason.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('A reason is required.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final viewModel = Provider.of<ContributionsViewModel>(
                  this.context,
                  listen: false);
              final bool success;
              if (action == 'approve') {
                success = await viewModel.approveContribution(id);
              } else if (action == 'archive') {
                success = await viewModel.archiveContribution(id, reason);
              } else {
                success = await viewModel.rejectContribution(id, reason);
              }
              if (!mounted) {
                return;
              }
              Navigator.of(this.context).pop();
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Contribution ${action}d successfully.'
                        : (viewModel.actionError ??
                            'Failed to $action contribution.'),
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: Text(action[0].toUpperCase() + action.substring(1),
                style: TextStyle(
                    color:
                        action == 'approve' ? AppColors.primary : Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddContributionDialog(BuildContext ctx) {
    final amountController = TextEditingController();
    final apiService = ApiService();
    DateTime selectedDate = DateTime.now();

    // State for the dialog
    List<Map<String, dynamic>> members = [];
    List<Map<String, dynamic>> groups = [];
    int? selectedUserId;
    int? selectedGroupId;
    bool isLoadingData = true;
    bool isSubmitting = false;

    showDialog(
      context: ctx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Load data on first build
            if (isLoadingData && members.isEmpty && groups.isEmpty) {
              _loadFormData(apiService).then((data) {
                setDialogState(() {
                  members = data['members'] ?? [];
                  groups = data['groups'] ?? [];
                  isLoadingData = false;
                });
              });
            }

            // Find selected member's group IDs to filter the group dropdown
            List<int> memberGroupIds = [];
            if (selectedUserId != null) {
              final member = members.firstWhere(
                  (m) => m['id'] == selectedUserId,
                  orElse: () => {});
              if (member.containsKey('group_ids')) {
                memberGroupIds = List<int>.from(member['group_ids']);
              }
            }

            final filteredGroups =
                groups.where((g) => memberGroupIds.contains(g['id'])).toList();

            // Auto-select if only one group
            if (filteredGroups.length == 1 && selectedGroupId == null) {
              selectedGroupId = filteredGroups.first['id'];
            }

            return AlertDialog(
              title: const Text('Add Member Contribution'),
              content: isLoadingData
                  ? const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Member dropdown
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Select Member',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            initialValue: selectedUserId,
                            hint: const Text('Choose a member'),
                            items: members.map((m) {
                              final name = m['full_name'] ??
                                  m['email'] ??
                                  'User ${m['id']}';
                              return DropdownMenuItem<int>(
                                value: m['id'],
                                child: Text(name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedUserId = val;
                                selectedGroupId =
                                    null; // Reset group selection when member changes
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Group dropdown (only show if multiple groups for this member)
                          if (filteredGroups.length > 1) ...[
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Group',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                              ),
                              initialValue: selectedGroupId,
                              hint: const Text('Choose a group'),
                              items: filteredGroups.map((g) {
                                return DropdownMenuItem<int>(
                                  value: g['id'],
                                  child: Text(g['name'] ?? 'Group ${g['id']}'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() => selectedGroupId = val);
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Amount field
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount (KES)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.payments),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date picker
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
                          // Validate
                          if (selectedUserId == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a member')),
                            );
                            return;
                          }
                          if (selectedGroupId == null) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a group')),
                            );
                            return;
                          }
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a valid amount')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final viewModel = Provider.of<ContributionsViewModel>(
                              context,
                              listen: false);
                          final errorMessage =
                              await viewModel.adminAddContribution(
                            userId: selectedUserId!,
                            groupId: selectedGroupId!,
                            amount: amount,
                            paidDate:
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
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

  Future<Map<String, List<Map<String, dynamic>>>> _loadFormData(
      ApiService apiService) async {
    try {
      final results = await Future.wait([
        apiService.getUsers(approvedOnly: true),
        apiService.getGroups(),
      ]);

      final membersList = (results[0].data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final groupsList = (results[1].data as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      return {'members': membersList, 'groups': groupsList};
    } catch (e) {
      debugPrint('Error loading form data: $e');
      return {'members': [], 'groups': []};
    }
  }
}
