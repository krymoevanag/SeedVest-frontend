import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../dashboard/member_dashboard.dart';
import '../finance/contributions_view.dart';
import '../dashboard/analytics_view.dart';
import '../finance/investments_view.dart';
import '../dashboard/admin_dashboard.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  List<Widget> _screens = []; // Initialize empty

  List<String> _titles = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userViewModel = context.watch<UserViewModel>();

    // Rebuild screens list based on role
    _screens = [
      userViewModel.isAdmin ? const AdminDashboard() : const MemberDashboard(),
      const AnalyticsView(),
      const ContributionsView(),
      const InvestmentsView(),
    ];

    _titles = [
      userViewModel.isAdmin ? 'Admin Dashboard' : 'SeedVest',
      'Financial Analytics',
      'My Contributions',
      'Group Investments',
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final user = userViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
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
            if (userViewModel.isTreasurer) ...[
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text('GOVERNANCE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ListTile(
                leading: const Icon(Icons.how_to_reg_outlined),
                title: const Text('Member Approvals'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/governance/approvals');
                },
              ),
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
                title: const Text('Role Management'),
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
              leading: const Icon(Icons.article_outlined),
              title: const Text('Terms & Conditions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/terms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
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
        ],
      ),
    );
  }
}
