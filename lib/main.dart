import 'package:app_links/app_links.dart';
import 'views/auth/reset_password_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/cache/cache_service.dart';
import 'views/auth/splash_screen.dart';
import 'views/auth/onboarding_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/forgot_password_screen.dart';
import 'views/auth/activation_waiting_screen.dart';
import 'views/navigation/main_navigation.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/contributions_viewmodel.dart';
import 'viewmodels/penalties_viewmodel.dart';
import 'views/finance/penalties_view.dart';
import 'viewmodels/governance_viewmodel.dart';
import 'viewmodels/finance_viewmodel.dart';
import 'views/governance/member_approval_view.dart';
import 'views/governance/finance_management_view.dart';
import 'views/governance/investment_management_view.dart';
import 'views/governance/audit_logs_view.dart';
import 'views/governance/member_management_view.dart';
import 'views/profile/profile_screen.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/notifications/notification_center_view.dart';
import 'views/governance/admin_broadcast_view.dart';
import 'views/governance/contribution_management_view.dart';
import 'views/governance/admin_member_registration_view.dart';
import 'views/finance/financial_insights_view.dart';
import 'views/finance/financial_reports_view.dart';
import 'views/finance/auto_saving_config_view.dart';
import 'views/finance/savings_targets_view.dart';
import 'views/support/help_screen.dart';
import 'views/support/terms_conditions_screen.dart';
import 'views/support/about_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize cache service
  await CacheService.init();

  // Request Notification Permissions
  await _requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => ContributionsViewModel()),
        ChangeNotifierProvider(create: (_) => PenaltiesViewModel()),
        ChangeNotifierProvider(create: (_) => GovernanceViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => FinanceViewModel()),
      ],
      child: const SeedVestApp(),
    ),
  );
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}

class SeedVestApp extends StatefulWidget {
  const SeedVestApp({super.key});

  @override
  State<SeedVestApp> createState() => _SeedVestAppState();
}

class _SeedVestAppState extends State<SeedVestApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 🔹 Handle app opened from terminated state
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // 🔹 Handle app opened from background
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    // Expected format:
    // seedvest://reset-password/<uid>/<token>
    debugPrint('Deep link received: $uri');

    if (uri.scheme == 'seedvest' && uri.host == 'reset-password') {
      if (uri.pathSegments.length >= 2) {
        final uid = uri.pathSegments[0];
        final token = uri.pathSegments[1];

        // Defer navigation to ensure the widget tree and navigator are ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushNamed(
              '/reset-password',
              arguments: {
                'uid': uid,
                'token': token,
              },
            );
          }
        });
      } else {
        debugPrint('Deep link missing uid/token segments: ${uri.pathSegments}');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

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
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/register': (context) => const RegisterScreen(),
        '/activation-waiting': (context) => const ActivationWaitingScreen(),
        '/dashboard': (context) => const MainNavigation(),
        '/penalties': (context) => const PenaltiesView(),
        '/governance/approvals': (context) => const MemberApprovalView(),
        '/governance/approvals/': (context) => const MemberApprovalView(),
        '/governance/pending-approvals': (context) =>
            const MemberApprovalView(),
        '/pending-approvals': (context) => const MemberApprovalView(),
        '/governance/finance': (context) => const FinanceManagementView(),
        '/governance/investments': (context) =>
            const InvestmentManagementView(),
        '/governance/audit': (context) => const AuditLogsView(),
        '/governance/roles': (context) => const MemberManagementView(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationCenterView(),
        '/governance/broadcast': (context) => const AdminBroadcastView(),
        '/governance/contributions': (context) =>
            const ContributionManagementView(),
        '/governance/register-member': (context) =>
            const AdminMemberRegistrationView(),
        '/finance/insights': (context) => const FinancialInsightsView(),
        '/finance/reports': (context) => const FinancialReportsView(),
        '/finance/auto-savings': (context) => const AutoSavingConfigView(),
        '/finance/targets': (context) => const SavingsTargetsView(),
        '/help': (context) => const HelpScreen(),
        '/terms': (context) => const TermsConditionsScreen(),
        '/about': (context) => const AboutUsScreen(),

        // 🔥 Reset Password Route
        '/reset-password': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;

          return ResetPasswordScreen(
            uid: args['uid'],
            token: args['token'],
          );
        },
      },
    );
  }
}
