import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../widgets/seedvest_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final biometricEnabled = await _apiService.isBiometricEnabled();
    final hasRefreshToken = await _apiService.hasRefreshToken();
    final canAuthenticate = await _biometricService.canAuthenticate();

    if (biometricEnabled && hasRefreshToken && canAuthenticate) {
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (lifecycleState == AppLifecycleState.resumed) {
        final authenticated = await _biometricService.authenticate(
          reason: 'Authenticate to sign in to SeedVest',
        );

        if (authenticated) {
          final refreshed = await _apiService.refreshAccessToken();
          if (refreshed) {
            if (!mounted) return;
            final userViewModel = Provider.of<UserViewModel>(
              context,
              listen: false,
            );
            await userViewModel.fetchProfile();

            if (!mounted) return;
            if (userViewModel.currentUser != null) {
              Navigator.pushReplacementNamed(context, '/dashboard');
              return;
            }
          } else {
            await _apiService.clearSessionAndBiometric();
          }
        }
      }
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SeedVestLogo(
                size: 190,
                wordmarkColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                'Financial Governance & Growth',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
