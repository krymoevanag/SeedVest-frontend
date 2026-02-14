import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'views/auth/splash_screen.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/activation_waiting_screen.dart';
import 'views/navigation/main_navigation.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/contributions_viewmodel.dart';
import 'viewmodels/penalties_viewmodel.dart';
import 'views/finance/penalties_view.dart';

import 'viewmodels/governance_viewmodel.dart';
import 'views/governance/member_approval_view.dart';
import 'views/governance/finance_management_view.dart';
import 'views/governance/audit_logs_view.dart';
import 'views/governance/role_management_view.dart';

import 'viewmodels/user_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ContributionsViewModel()),
        ChangeNotifierProvider(create: (_) => PenaltiesViewModel()),
        ChangeNotifierProvider(create: (_) => GovernanceViewModel()),
      ],
      child: const SeedVestApp(),
    ),
  );
}

class SeedVestApp extends StatelessWidget {
  const SeedVestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeedVest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/activation-waiting': (context) => const ActivationWaitingScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/penalties': (context) => const PenaltiesView(),
        '/governance/approvals': (context) => const MemberApprovalView(),
        '/governance/finance': (context) => const FinanceManagementView(),
        '/governance/audit': (context) => const AuditLogsView(),
        '/governance/roles': (context) => const RoleManagementView(),
      },
    );
  }
}
