import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_service.dart';
import '../widgets/custom_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.confirmPasswordReset(
        uid: widget.uid,
        token: widget.token,
        newPassword: _passwordController.text.trim(),
      );

      if (!mounted) return;

      final message = response.data['detail'] ?? 'Password reset successful.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } on DioException catch (e) {
      if (!mounted) return;

      final error = e.response?.data['detail'] ??
          e.response?.data['non_field_errors']?.first ??
          'Reset failed. Try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
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
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Password is required';
                  if (value.length < 8) return "Minimum 8 characters required";

                  bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
                  bool hasDigits = RegExp(r'\d').hasMatch(value);
                  bool hasSpecial =
                      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

                  if (!hasLetters || !hasDigits || !hasSpecial) {
                    return 'Must include letters, numbers and special characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "RESET PASSWORD",
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _resetPassword,
              )
            ],
          ),
        ),
      ),
    );
  }
}
