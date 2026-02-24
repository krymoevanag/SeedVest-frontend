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
import 'views/governance/member_approval_view.dart';
import 'views/governance/finance_management_view.dart';
import 'views/governance/audit_logs_view.dart';
import 'views/governance/role_management_view.dart';
import 'views/profile/profile_screen.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/notification_viewmodel.dart';
import 'views/notifications/notification_center_view.dart';
import 'views/governance/admin_broadcast_view.dart';
import 'views/governance/contribution_management_view.dart';
import 'views/governance/admin_member_registration_view.dart';

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

    if (uri.scheme == 'seedvest' && uri.host == 'reset-password') {
      if (uri.pathSegments.length >= 2) {
        final uid = uri.pathSegments[0];
        final token = uri.pathSegments[1];

        Navigator.of(context).pushNamed(
          '/reset-password',
          arguments: {
            'uid': uid,
            'token': token,
          },
        );
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
        '/governance/finance': (context) => const FinanceManagementView(),
        '/governance/audit': (context) => const AuditLogsView(),
        '/governance/roles': (context) => const RoleManagementView(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationCenterView(),
        '/governance/broadcast': (context) => const AdminBroadcastView(),
        '/governance/contributions': (context) =>
            const ContributionManagementView(),
        '/governance/register-member': (context) =>
            const AdminMemberRegistrationView(),

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
