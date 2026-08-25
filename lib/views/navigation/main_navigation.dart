import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/colors.dart';
import '../../core/cache/cache_service.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../dashboard/member_dashboard.dart';
import '../finance/contributions_view.dart';
import '../finance/analytics_screen.dart';
import '../finance/investments_view.dart';
import '../finance/loans_overview_view.dart';
import '../dashboard/admin_dashboard.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/api_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;
  bool _isOnline = true;
  int _pendingWrites = 0;
  bool _isSyncingPendingWrites = false;
  late StreamSubscription<bool> _connectivitySubscription;
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  final ApiService _apiService = ApiService();

  List<Widget> _screens = []; // Initialize empty

  List<String> _titles = [];

  @override
  void initState() {
    super.initState();
    _connectivityService.init();
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
      }
      _refreshPendingWrites();
    });

    // Check initial status
    _connectivityService.isConnected.then((online) {
      if (mounted) {
        setState(() => _isOnline = online);
      }
    });

    _refreshPendingWrites();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().refreshNotificationsState();
    });
  }

  void _refreshPendingWrites() {
    final writes = _cacheService.getPendingWrites().length;
    if (mounted) {
      setState(() {
        _pendingWrites = writes;
      });
    }
  }

  Future<void> _syncPendingWrites() async {
    final messenger = ScaffoldMessenger.of(context);
    final pendingBefore = _cacheService.getPendingWrites().length;

    if (_isSyncingPendingWrites) return;

    if (pendingBefore == 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('There are no offline changes waiting to sync.'),
        ),
      );
      return;
    }

    if (!_isOnline) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'You are offline. Pending changes will sync once you reconnect.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSyncingPendingWrites = true;
    });

    try {
      await _apiService.syncPendingWrites();
      _refreshPendingWrites();

      if (!mounted) return;

      final pendingAfter = _cacheService.getPendingWrites().length;
      final syncedCount = pendingBefore - pendingAfter;

      if (syncedCount > 0 && pendingAfter == 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              syncedCount == 1
                  ? 'Offline change synced successfully.'
                  : '$syncedCount offline changes synced successfully.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (syncedCount > 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '$syncedCount change(s) synced. $pendingAfter still pending.',
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Sync did not complete yet. Pending changes will retry automatically.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to sync offline changes right now.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingPendingWrites = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userViewModel = context.watch<UserViewModel>();

    // Rebuild screens list based on role
    _screens = [
      userViewModel.canViewAdminDashboard
          ? const AdminDashboard()
          : const MemberDashboard(),
      const AnalyticsScreen(),
      const ContributionsView(),
      const InvestmentsView(),
      const LoansOverviewView(),
    ];

    _titles = [
      userViewModel.canViewAdminDashboard ? 'Admin Dashboard' : 'SeedVest',
      'Financial Analytics',
      'My Contributions',
      'Group Investments',
      'Loans',
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleNotificationMenuSelection(
    BuildContext context,
    String value,
  ) async {
    final notificationViewModel = context.read<NotificationViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    if (value == 'open') {
      await Navigator.pushNamed(context, '/notifications');
      if (!mounted) return;
      await notificationViewModel.refreshNotificationsState();
      return;
    }

    if (value == 'toggle_internal') {
      final target = !notificationViewModel.muteInternalMessages;
      final success =
          await notificationViewModel.setMuteInternalMessages(target);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (target
                    ? 'Internal messages silenced.'
                    : 'Internal messages enabled.')
                : 'Failed to update notification preference.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final notificationViewModel = context.watch<NotificationViewModel>();
    final user = userViewModel.currentUser;
    final unreadCount = notificationViewModel.unreadCountForBar;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        final backButtonHasNotBeenPressedRecently = _lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedRecently) {
          _lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tap back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // If we reach here, it means the second tap was within 2 seconds.
        // We trigger a system-level pop to exit the app gracefully.
        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Notifications',
              onSelected: (value) =>
                  _handleNotificationMenuSelection(context, value),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'open',
                  child: Text('Open notifications'),
                ),
                if (!userViewModel.isAdmin)
                  PopupMenuItem<String>(
                    value: 'toggle_internal',
                    child: Text(
                      notificationViewModel.muteInternalMessages
                          ? 'Enable internal messages'
                          : 'Silence internal messages',
                    ),
                  ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_pendingWrites > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Tooltip(
                  message: _isSyncingPendingWrites
                      ? 'Syncing offline changes...'
                      : '$_pendingWrites offline request(s) pending sync. Tap to sync now',
                  child: IconButton(
                    onPressed:
                        _isSyncingPendingWrites ? null : _syncPendingWrites,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (_isSyncingPendingWrites)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.sync, size: 24),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              _pendingWrites > 99
                                  ? '99+'
                                  : _pendingWrites.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: user?.profilePicture != null
                  ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(user!.profilePicture!),
                    )
                  : const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(user?.fullName ?? 'SeedVest Member'),
                accountEmail: Text(user?.email ?? 'member@seedvest.com'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profilePicture != null
                      ? NetworkImage(user!.profilePicture!)
                      : null,
                  child: user?.profilePicture == null
                      ? const Icon(Icons.person, color: AppColors.primary)
                      : null,
                ),
                decoration: const BoxDecoration(color: AppColors.primary),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: const Text('Penalties'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/penalties');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text('FINANCE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.show_chart_outlined),
                title: const Text('Financial Analytics'),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(1); // Index of AnalyticsScreen
                },
              ),
              ListTile(
                leading: const Icon(Icons.summarize_outlined),
                title: const Text('Financial Reports'),
                onTap: () {
                  Navigator.pop(context);
                  if (userViewModel.isFinancialSecretary) {
                    Navigator.pushNamed(context, '/finance/reports/oversight');
                  } else {
                    Navigator.pushNamed(context, '/finance/reports');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.autorenew_outlined),
                title: const Text('Auto-Savings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/finance/auto-savings');
                },
              ),
              ListTile(
                leading: const Icon(Icons.track_changes_outlined),
                title: const Text('Savings Goals'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/finance/targets');
                },
              ),
              if (userViewModel.isTreasurer ||
                  userViewModel.isFinancialSecretary) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Text('GOVERNANCE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                if (userViewModel.isAdmin || userViewModel.isTreasurer) ...[
                  ListTile(
                    leading: const Icon(Icons.how_to_reg_outlined),
                    title: const Text('Member Approvals'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/governance/approvals');
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('Finance Management'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/governance/finance');
                  },
                ),
              ],
              if (userViewModel.isAdmin) ...[
                const Divider(),
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                  child: Text('ADMINISTRATION',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Audit Logs'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/governance/audit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined),
                  title: const Text('Members & Groups'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/governance/roles');
                  },
                ),
              ],
              const Divider(),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/help');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  final userViewModel = context.read<UserViewModel>();
                  await userViewModel.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (!_isOnline)
              Container(
                width: double.infinity,
                color: Colors.orange.shade800,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 12),
                    Text(
                      'Offline Mode: Viewing cached data',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Finance'),
            BottomNavigationBarItem(
                icon: Icon(Icons.trending_up), label: 'Invest'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance), label: 'Loans'),
          ],
        ),
      ),
    );
  }
}
