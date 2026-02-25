import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/colors.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
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
      context.read<NotificationViewModel>().refreshNotificationsState();
    });
  }

  Widget _buildNotificationList({
    required List<NotificationModel> notifications,
    required NotificationViewModel viewModel,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyTitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              emptySubtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getIconForType(notif.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight:
                                notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(notif.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationViewModel = context.watch<NotificationViewModel>();
    final userViewModel = context.watch<UserViewModel>();
    final notifications = notificationViewModel.notifications;
    final isAdminLike = userViewModel.isAdmin || userViewModel.isTreasurer;
    final canSilence = !userViewModel.isAdmin;

    final tabs = <Tab>[
      const Tab(text: 'All'),
      if (isAdminLike) const Tab(text: 'Proposals'),
      const Tab(text: 'Internal'),
    ];

    final tabViews = <Widget>[
      _buildNotificationList(
        notifications: notifications,
        viewModel: notificationViewModel,
        emptyTitle: 'No notifications yet',
        emptySubtitle: 'You will see account and finance updates here.',
      ),
      if (isAdminLike)
        _buildNotificationList(
          notifications: notificationViewModel.proposalNotifications,
          viewModel: notificationViewModel,
          emptyTitle: 'No proposal alerts',
          emptySubtitle: 'Manual contribution proposals will appear here.',
        ),
      _buildNotificationList(
        notifications: notificationViewModel.internalNotifications,
        viewModel: notificationViewModel,
        emptyTitle: notificationViewModel.muteInternalMessages
            ? 'Internal messages silenced'
            : 'No internal messages',
        emptySubtitle: notificationViewModel.muteInternalMessages
            ? 'Turn off silence to receive internal notices again.'
            : 'Broadcast messages from admins show up here.',
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: TabBar(isScrollable: tabs.length > 2, tabs: tabs),
          actions: [
            if (notifications.isNotEmpty)
              TextButton(
                onPressed: () => notificationViewModel.markAllAsRead(),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            if (canSilence)
              SwitchListTile.adaptive(
                value: notificationViewModel.muteInternalMessages,
                onChanged: (value) async {
                  final success = await notificationViewModel
                      .setMuteInternalMessages(value);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? (value
                                ? 'Internal messages silenced.'
                                : 'Internal messages enabled.')
                            : 'Failed to update notification preference.',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                },
                title: const Text('Silence internal messages'),
                subtitle: const Text(
                  'Hide internal broadcasts in your center and bell alerts.',
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: notificationViewModel.refreshNotificationsState,
                child: TabBarView(children: tabViews),
              ),
            ),
          ],
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
