import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/contributions_viewmodel.dart';
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
  String _formatPaymentMethod(String? method) {
    if (method == null || method.isEmpty) {
      return 'N/A';
    }
    return method
        .toLowerCase()
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContributionsViewModel>().fetchContributions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContributionsViewModel>();
    // Only show PENDING contributions for management
    final pendingContributions =
        viewModel.contributions.where((c) => c.status == 'PENDING').toList();
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
          : pendingContributions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No pending contributions',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.fetchContributions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingContributions.length,
                    itemBuilder: (context, index) {
                      final contribution = pendingContributions[index];
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
                                    Text(
                                      'Member ID: ${contribution.userId}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      currencyFormat
                                          .format(contribution.amount),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Submitted: ${DateFormat('dd MMM yyyy').format(contribution.date)}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Group ID: ${contribution.groupId}',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
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
                                      'Manual proposal',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Method: ${_formatPaymentMethod(contribution.reportedPaymentMethod)}',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 13),
                                  ),
                                  if (contribution.reportedPaidDate != null)
                                    Text(
                                      'Reported paid date: ${DateFormat('dd MMM yyyy').format(contribution.reportedPaidDate!)}',
                                      style: TextStyle(
                                          color: Colors.grey[700], fontSize: 13),
                                    ),
                                  if ((contribution.reportedReference ?? '')
                                      .isNotEmpty)
                                    Text(
                                      'Reference: ${contribution.reportedReference}',
                                      style: TextStyle(
                                          color: Colors.grey[700], fontSize: 13),
                                    ),
                                  if ((contribution.reportedNote ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Note: ${contribution.reportedNote}',
                                        style: TextStyle(
                                            color: Colors.grey[700], fontSize: 13),
                                      ),
                                    ),
                                ],
                                if (contribution.transactionId != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tx ID: ${contribution.transactionId}',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                                const SizedBox(height: 16),
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

  void _confirmAction(BuildContext context, String action, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            '${action[0].toUpperCase()}${action.substring(1)} Contribution'),
        content: Text('Are you sure you want to $action this contribution?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final viewModel = Provider.of<ContributionsViewModel>(
                  this.context,
                  listen: false);
              if (action == 'approve') {
                viewModel.approveContribution(id);
              } else {
                viewModel.rejectContribution(id);
              }
              Navigator.pop(context);
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
                  if (groups.length == 1) {
                    selectedGroupId = groups.first['id'];
                  }
                  isLoadingData = false;
                });
              });
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
                                child:
                                    Text(name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() => selectedUserId = val);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Group dropdown (only show if multiple groups)
                          if (groups.length > 1) ...[
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Select Group',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                              ),
                              initialValue: selectedGroupId,
                              hint: const Text('Choose a group'),
                              items: groups.map((g) {
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
                          final success = await viewModel.adminAddContribution(
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
                                content: Text(success
                                    ? 'Contribution added successfully!'
                                    : 'Failed to add contribution'),
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
