import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

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
                        Icon(Icons.person_outline, size: 64, color: Colors.grey),
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
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(user.fullName.substring(0, 1)),
                                ),
                                title: Text(
                                  user.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(user.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () {}, // Show details
                                ),
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Approve',
                                      onPressed: () async {
                                        bool success = await viewModel.approveUser(user.id);
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('${user.fullName} approved!')),
                                          );
                                        }
                                      },
                                      isLoading: viewModel.isLoading,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {}, // TODO: Reject
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text('Reject', style: TextStyle(color: Colors.red)),
                                    ),
                                  ),
                                ],
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
}
