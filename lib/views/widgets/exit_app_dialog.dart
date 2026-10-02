import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_viewmodel.dart';

/// Displays a modern confirmation dialog to exit the application.
/// Performs complete authentication data cleanup, SharedPreferences wipe,
/// route stack clearance, and application termination.
Future<void> showExitAppDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return const _ExitAppDialogContent();
    },
  );
}

class _ExitAppDialogContent extends StatefulWidget {
  const _ExitAppDialogContent();

  @override
  State<_ExitAppDialogContent> createState() => _ExitAppDialogContentState();
}

class _ExitAppDialogContentState extends State<_ExitAppDialogContent> {
  bool _isExiting = false;

  Future<void> _handleExit() async {
    setState(() {
      _isExiting = true;
    });

    try {
      final userViewModel = context.read<UserViewModel>();

      // Complete logout process (clears tokens, secure storage, SharedPreferences, cache, inactivity timer)
      await userViewModel.logout();

      if (!mounted) return;

      // Close dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Clear navigation stack and redirect to Login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      // Terminate app on Android / mobile
      await SystemNavigator.pop();
    } catch (e) {
      debugPrint('Error during exit application: $e');

      if (!mounted) return;

      setState(() {
        _isExiting = false;
      });

      // Show error snackbar if logout encounters an issue
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete application exit: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.power_settings_new_rounded,
              color: Colors.red.shade700,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Exit Application',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: _isExiting
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Exiting SeedVest and clearing session data...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : const Text(
              'Are you sure you want to exit SeedVest? You will be logged out and will need to sign in again when you reopen the app.',
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: _isExiting
          ? []
          : [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _handleExit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Exit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
    );
  }
}
