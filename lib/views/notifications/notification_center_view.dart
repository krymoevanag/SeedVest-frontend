import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_card.dart';

class NotificationCenterView extends StatefulWidget {
  const NotificationCenterView({super.key});

  @override
  State<NotificationCenterView> createState() => _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<NotificationCenterView> {
  String? _normalizeRoute(String? rawLink) {
    if (rawLink == null || rawLink.isEmpty) return null;

    final link = rawLink.trim();
    const aliases = {
      '/governance/approvals/': '/governance/approvals',
      '/governance/pending-approvals': '/governance/approvals',
      '/pending-approvals': '/governance/approvals',
    };

    return aliases[link] ?? link;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<NotificationViewModel>();
    final notifications = viewModel.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => viewModel.markAllAsRead(),
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No notifications yet',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: viewModel.fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: CustomCard(
                          onTap: () {
                            if (!notif.isRead) {
                              viewModel.markAsRead(notif.id);
                            }
                            final route = _normalizeRoute(notif.link);
                            if (route != null) {
                              Navigator.pushNamed(context, route);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: notif.isRead
                                  ? null
                                  : const Border(
                                      left: BorderSide(
                                          color: AppColors.primary, width: 4)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _getIconForType(notif.type),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontWeight: notif.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(notif.message,
                                          style: TextStyle(
                                              color: Colors.grey[700])),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm')
                                            .format(notif.createdAt),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
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

  Widget _getIconForType(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'SUCCESS':
        iconData = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'WARNING':
        iconData = Icons.warning_amber_rounded;
        color = Colors.orange;
        break;
      case 'ERROR':
        iconData = Icons.error_outline;
        color = Colors.red;
        break;
      default:
        iconData = Icons.info_outline;
        color = AppColors.primary;
    }

    return Icon(iconData, color: color, size: 28);
  }
}
