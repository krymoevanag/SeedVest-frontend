import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_button.dart';

class ActivationWaitingScreen extends StatelessWidget {
  const ActivationWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 100,
                color: AppColors.accent, // Gold icon
              ),
              const SizedBox(height: 32),
              Text(
                'Registration Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your account has been created and is currently awaiting approval from a SeedVest administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'A notification will be sent to your email once your membership is verified.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'BACK TO LOGIN',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
