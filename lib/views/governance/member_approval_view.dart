import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../../viewmodels/user_viewmodel.dart';

class MemberApprovalView extends StatefulWidget {
  const MemberApprovalView({super.key});

  @override
  State<MemberApprovalView> createState() => _MemberApprovalViewState();
}

class _MemberApprovalViewState extends State<MemberApprovalView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernanceViewModel>().fetchPendingUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Member Approvals')),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchPendingUsers,
        child: viewModel.isLoading && viewModel.pendingUsers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : viewModel.pendingUsers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No pending approvals at the moment.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.pendingUsers.length,
                    itemBuilder: (context, index) {
                      final user = viewModel.pendingUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(user.fullName.isNotEmpty
                                      ? user.fullName.substring(0, 1)
                                      : '?'),
                                ),
                                title: Text(
                                  user.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    const SizedBox(height: 4),
                                    _buildStatusChip(user.applicationStatus),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _showDeleteConfirmDialog(
                                          context, user.id, user.fullName),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      onPressed: () {}, // Show details
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              if (context.read<UserViewModel>().isTreasurer)
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Approve',
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          bool success = await viewModel
                                              .approveUser(user.id);
                                          if (success && mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      '${user.fullName} approved!')),
                                            );
                                          }
                                        },
                                        isLoading: viewModel.isLoading,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showRejectDialog(
                                            context, user.id, user.fullName),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          side:
                                              const BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text('Reject',
                                            style: TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      'Read-only oversight access',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, int userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to permanently delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              navigator.pop();
              bool success =
                  await context.read<GovernanceViewModel>().deleteUser(userId);
              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$userName deleted successfully.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'PENDING':
        color = AppColors.warning;
        break;
      case 'UNDER_REVIEW':
        color = AppColors.secondary;
        break;
      case 'APPROVED':
        color = AppColors.success;
        break;
      case 'REJECTED':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int userId, String userName) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject $userName'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Enter reason for rejection',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              navigator.pop();
              bool success = await context
                  .read<GovernanceViewModel>()
                  .rejectUser(userId, reason);
              if (success && mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$userName rejected.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
