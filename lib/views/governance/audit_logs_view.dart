import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../widgets/custom_card.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernanceViewModel>().fetchAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GovernanceViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: RefreshIndicator(
        onRefresh: viewModel.fetchAuditLogs,
        child: viewModel.isLoading && viewModel.auditLogs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : viewModel.auditLogs.isEmpty
                ? const Center(child: Text('No audit logs found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: viewModel.auditLogs.length,
                    itemBuilder: (context, index) {
                      final log = viewModel.auditLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blueGrey,
                              child: Icon(Icons.history, color: Colors.white),
                            ),
                            title: Text(
                              log.displayTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(log.notes),
                                if (log.actorEmail.isNotEmpty)
                                  Text(
                                    "By: ${log.actorEmail}",
                                    style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('MMM dd, yyyy - HH:mm').format(log.timestamp),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
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
}
