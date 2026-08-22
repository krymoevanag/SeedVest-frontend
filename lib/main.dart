import 'package:app_links/app_links.dart';
import 'views/auth/reset_password_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/cache/cache_service.dart';
import 'core/services/inactivity_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/colors.dart';
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
import 'views/finance/financial_secretary_report_view.dart';
import 'views/finance/auto_saving_config_view.dart';
import 'views/finance/savings_targets_view.dart';
import 'views/support/help_screen.dart';
import 'views/support/terms_conditions_screen.dart';
import 'views/support/about_us_screen.dart';
import 'views/widgets/inactivity_detector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize cache service
  await CacheService.init();

  // Request Notification Permissions
  await _requestPermissions();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _setupInactivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.initialize(
        onForegroundMessage: _handleForegroundPush,
        onNotificationTap: _handlePushNotificationTap,
      );
    });
  }

  void _handleForegroundPush(RemoteMessage message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    context.read<NotificationViewModel>().refreshNotificationsState();
  }

  void _handlePushNotificationTap(String? link) {
    final route = _routeForNotificationLink(link);
    _navigatorKey.currentState?.pushNamed(route);
  }

  String _routeForNotificationLink(String? link) {
    if (link == '/dashboard') return '/dashboard';
    if (link != null && link.startsWith('/finance/penalties')) return '/penalties';
    if (link == '/governance/contributions') return '/governance/contributions';
    if (link == '/governance/approvals') return '/governance/approvals';
    if (link == '/governance/investments') return '/governance/investments';
    return '/notifications';
  }

  void _setupInactivity() {
    final svc = InactivityService.instance;
    svc.onWarning = _showInactivityWarning;
    svc.onTimeout = _performAutoLogout;
  }

  void _showInactivityWarning() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    int secondsLeft = InactivityService.warningDuration.inSeconds;
    Timer? countdownTimer;
    bool dialogOpen = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        dialogOpen = true;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (secondsLeft <= 1) {
                t.cancel();
                if (dialogOpen && dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                return;
              }
              if (dialogContext.mounted) {
                setDialogState(() => secondsLeft--);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.access_time_filled,
                      color: Colors.orange.shade700, size: 28),
                  const SizedBox(width: 10),
                  const Text('Still there?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'You have been inactive for a while. For your security, you will be logged out in:'),
                  const SizedBox(height: 20),
                  Text(
                    '$secondsLeft',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: secondsLeft <= 10
                          ? Colors.red
                          : Colors.orange.shade700,
                    ),
                  ),
                  Text('second${secondsLeft == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    dialogOpen = false;
                    Navigator.of(dialogContext).pop();
                    _performAutoLogout();
                  },
                  child: const Text('Log Out',
                      style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    dialogOpen = false;
                    Navigator.of(dialogContext).pop();
                    InactivityService.instance.resetTimer();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  child: const Text('Stay Logged In',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
      dialogOpen = false;
    });
  }

  Future<void> _performAutoLogout() async {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final userViewModel = context.read<UserViewModel>();
    await userViewModel.logout();

    if (_navigatorKey.currentState != null) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (_) => false,
        arguments: {'session_expired': true},
      );
    }
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
    debugPrint('Deep link received: $uri');

    if (uri.scheme == 'seedvest' && uri.host == 'reset-password') {
      if (uri.pathSegments.length >= 2) {
        final uid = uri.pathSegments[0];
        final token = uri.pathSegments[1];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigatorKey.currentState?.pushNamed(
              '/reset-password',
              arguments: {
                'uid': uid,
                'token': token,
              },
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    PushNotificationService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'SeedVest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      builder: (context, child) {
        return InactivityDetector(
          child: child ?? const SizedBox.shrink(),
        );
      },
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
        '/finance/reports/oversight': (context) => const FinancialSecretaryReportView(),
        '/finance/auto-savings': (context) => const AutoSavingConfigView(),
        '/finance/targets': (context) => const SavingsTargetsView(),
        '/help': (context) => const HelpScreen(),
        '/terms': (context) => const TermsConditionsScreen(),
        '/about': (context) => const AboutUsScreen(),
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
