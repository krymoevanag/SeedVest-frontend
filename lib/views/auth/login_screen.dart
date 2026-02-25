// lib/views/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/seedvest_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _canUseBiometricLogin = false;
  String _biometricLabel = 'Biometrics';

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await _apiService.isBiometricEnabled();
    final hasRefreshToken = await _apiService.hasRefreshToken();
    final canAuthenticate = await _biometricService.canAuthenticate();
    final label = await _biometricService.biometricLabel();

    if (!mounted) return;
    setState(() {
      _biometricLabel = label;
      _canUseBiometricLogin = enabled && hasRefreshToken && canAuthenticate;
    });
  }

  Future<void> _maybePromptBiometricOptIn() async {
    final alreadyEnabled = await _apiService.isBiometricEnabled();
    final canAuthenticate = await _biometricService.canAuthenticate();

    if (alreadyEnabled || !canAuthenticate || !mounted) return;

    final label = await _biometricService.biometricLabel();
    if (!mounted) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable $label Login?'),
        content: Text(
          'Use $label for faster sign in on this device. '
          'You can disable it anytime in Profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldEnable != true || !mounted) return;

    final authenticated = await _biometricService.authenticate(
      reason: 'Confirm biometric setup for SeedVest',
    );

    if (!authenticated || !mounted) return;

    await _apiService.setBiometricEnabled(true);
    await _loadBiometricState();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label login enabled.'),
      ),
    );
  }

  Future<void> _handleBiometricLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to sign in to SeedVest',
      );
      if (!authenticated) return;

      final refreshed = await _apiService.refreshAccessToken();
      if (!refreshed) {
        await _apiService.clearSessionAndBiometric();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login with email/password.'),
            backgroundColor: Colors.orange,
          ),
        );
        await _loadBiometricState();
        return;
      }

      if (!mounted) return;
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      await userViewModel.fetchProfile();
      if (mounted && userViewModel.currentUser != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Fetch user profile to update UserViewModel state
        if (mounted) {
          final userViewModel =
              Provider.of<UserViewModel>(context, listen: false);
          await userViewModel.fetchProfile();
          if (mounted) {
            await _maybePromptBiometricOptIn();
          }
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;

      String errorMessage = "An error occurred. Please try again.";

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        errorMessage =
            "Unable to connect to server. Please check your internet connection.";
      } else if (e.response != null) {
        final status = e.response?.statusCode;
        final data = e.response?.data;

        if (status == 401) {
          errorMessage = "Invalid email or password. Please try again.";
        } else if (status == 403) {
          if (data is Map && data.containsKey("error")) {
            final backendError = data["error"].toString();
            if (backendError.toLowerCase().contains("not activated")) {
              errorMessage =
                  "Your account is not activated yet. Please use your activation email first.";
            } else if (backendError.toLowerCase().contains("account status")) {
              errorMessage =
                  "$backendError\nIf you just completed activation, wait for admin approval.";
            } else {
              errorMessage = backendError;
            }
          } else {
            errorMessage = "Account access denied. Please contact support.";
          }
        } else if (status! >= 500) {
          errorMessage = "Server error. Please try again later.";
        } else if (data is Map && data.containsKey("detail")) {
          errorMessage = data["detail"].toString();
        } else if (data is Map && data.containsKey("non_field_errors")) {
          errorMessage = (data["non_field_errors"] as List).first.toString();
        } else if (data is Map && data.containsKey("error")) {
          errorMessage = data["error"].toString();
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: SeedVestLogo(size: 130),
                ),
                const SizedBox(height: 24),
                Text(
                  "Welcome Back!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Sign in to continue your investment journey",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) return "Invalid email address";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: "LOGIN",
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleLogin,
                ),
                if (_canUseBiometricLogin) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleBiometricLogin,
                    icon: const Icon(Icons.fingerprint),
                    label: Text('LOGIN WITH $_biometricLabel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        "Register",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
