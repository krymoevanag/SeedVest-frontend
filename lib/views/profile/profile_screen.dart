import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../viewmodels/user_viewmodel.dart';
import '../../data/models/user.dart';
import '../../core/security/biometric_service.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricLabel = 'Biometrics';

  // Track the last user we synced controllers from to avoid redundant updates.
  User? _syncedUser;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserViewModel>().currentUser;

    _firstNameController = TextEditingController(
      text: user?.firstName ?? (user?.fullName.split(' ').first ?? ''),
    );
    _lastNameController = TextEditingController(
      text: user?.lastName ??
          (user != null && user.fullName.split(' ').length > 1
              ? user.fullName.split(' ').sublist(1).join(' ')
              : ''),
    );
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _syncedUser = user;
    _loadBiometricSettings();

    // Refresh profile from API so the screen never shows stale/blank data.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().fetchProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Keep text controllers in sync whenever the UserViewModel notifies a
    // change (e.g., after fetchProfile() completes), but only when not editing
    // so we don't clobber the user's in-progress edits.
    if (!_isEditing) {
      final user = context.read<UserViewModel>().currentUser;
      if (user != null && user != _syncedUser) {
        _firstNameController.text =
            user.firstName ?? (user.fullName.split(' ').first);
        _lastNameController.text = user.lastName ??
            (user.fullName.split(' ').length > 1
                ? user.fullName.split(' ').sublist(1).join(' ')
                : '');
        _phoneController.text = user.phoneNumber ?? '';
        _emailController.text = user.email;
        _syncedUser = user;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    final userViewModel = context.read<UserViewModel>();
    final canAuthenticate = await _biometricService.canAuthenticate();
    final enabled = await userViewModel.isBiometricEnabled();
    final label = await _biometricService.biometricLabel();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canAuthenticate;
      _biometricEnabled = enabled;
      _biometricLabel = label;
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final userViewModel = context.read<UserViewModel>();
    if (enabled) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric setup cancelled.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    await userViewModel.setBiometricEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled ? 'Biometric login enabled.' : 'Biometric login disabled.',
        ),
      ),
    );
  }

  Future<void> _showAvatarPicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Profile Photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined,
                    color: AppColors.primary),
                title: const Text('Take photo with camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.length();
      if (bytes > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 2MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _imageFile = file);

      if (mounted) {
        final success = await context
            .read<UserViewModel>()
            .updateProfilePicture(pickedFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Profile picture updated!'
                  : 'Failed to upload image'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    }
  }

  String _extractApiError(dynamic data) {
    if (data is Map) {
      const fieldPriority = [
        'current_password',
        'new_password',
        'confirm_password',
        'non_field_errors',
        'detail',
        'error',
        'message',
      ];

      for (final key in fieldPriority) {
        if (!data.containsKey(key)) continue;
        final value = data[key];
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
    } else if (data is String && data.isNotEmpty) {
      return data;
    }

    return 'Failed to change password. Please try again.';
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submitChangePassword() async {
            if (!formKey.currentState!.validate()) return;

            final userViewModel = context.read<UserViewModel>();
            setDialogState(() => isSubmitting = true);
            try {
              final response = await userViewModel.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
                confirmPassword: confirmPasswordController.text,
              );

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              if (mounted) {
                final successMessage =
                    response.data is Map && response.data['message'] != null
                        ? response.data['message'].toString()
                        : 'Password changed successfully.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successMessage)),
                );
              }
            } on DioException catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_extractApiError(e.response?.data)),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Failed to change password. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (dialogContext.mounted) {
                setDialogState(() => isSubmitting = false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrentPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(
                              () => obscureCurrentPassword =
                                  !obscureCurrentPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Current password is required'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(
                              () => obscureNewPassword = !obscureNewPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setDialogState(
                              () => obscureConfirmPassword =
                                  !obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password';
                        }
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : submitChangePassword,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        },
      ),
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final user = userViewModel.currentUser;
    final isLoading = userViewModel.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
            icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _firstNameController.text = user?.firstName ??
                      (user?.fullName.split(' ').first ?? '');
                  _lastNameController.text = user?.lastName ??
                      (user != null && user.fullName.split(' ').length > 1
                          ? user.fullName.split(' ').sublist(1).join(' ')
                          : '');
                  _phoneController.text = user?.phoneNumber ?? '';
                  _emailController.text = user?.email ?? '';
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar & Name Header ─────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _showAvatarPicker,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (user?.profilePicture != null
                              ? NetworkImage(user!.profilePicture!)
                              : null) as ImageProvider?,
                      child:
                          (user?.profilePicture == null && _imageFile == null)
                              ? Text(
                                  user?.fullName.isNotEmpty == true
                                      ? user!.fullName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.fullName ?? 'Member',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (user?.email.isNotEmpty == true)
              Text(
                user!.email,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            const SizedBox(height: 20),

            // ── Membership Card ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF1E3A5F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membership No.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          user?.membershipNumber ?? 'Pending Assignment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: user?.isApproved == true
                          ? Colors.green.withValues(alpha: 0.25)
                          : Colors.orange.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: user?.isApproved == true
                            ? Colors.green[300]!
                            : Colors.orange[300]!,
                      ),
                    ),
                    child: Text(
                      user?.isApproved == true ? 'ACTIVE' : 'PENDING',
                      style: TextStyle(
                        color: user?.isApproved == true
                            ? Colors.green[200]
                            : Colors.orange[200],
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Navigation Shortcuts ───────────────────────────────────
            _buildSectionHeader('Financial Shortcuts'),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary),
                    title: const Text('My Financial Profile'),
                    subtitle: const Text('View savings, penalties & balance'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, '/finance/profile'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.account_balance,
                        color: Color(0xFF0D47A1)),
                    title: const Text('My Loans'),
                    subtitle:
                        const Text('Active loans, installments & repayments'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/finance/loans'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.teal),
                    title: const Text('Savings History'),
                    subtitle: const Text('Complete statement of transactions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, '/finance/history'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Personal Info Form ───────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Personal Information'),
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(
                          label: 'First Name',
                          controller: _firstNameController,
                          enabled: _isEditing,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          enabled: _isEditing,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          enabled: _isEditing,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          label: 'Email Address',
                          controller: _emailController,
                          enabled: _isEditing,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Save Changes',
                      isLoading: isLoading,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final success = await userViewModel.updateProfile({
                            'first_name': _firstNameController.text.trim(),
                            'last_name': _lastNameController.text.trim(),
                            'phone_number': _phoneController.text.trim(),
                            if (_emailController.text.trim().isNotEmpty)
                              'email': _emailController.text.trim(),
                          });

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Profile updated successfully!'
                                  : 'Failed to update profile. Please try again.'),
                              backgroundColor:
                                  success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success) setState(() => _isEditing = false);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Security ─────────────────────────────────────────────────────
            _buildSectionHeader('Security'),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (_biometricAvailable)
                    SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: Text('Enable $_biometricLabel Login'),
                      subtitle: const Text(
                        'Use biometrics for faster sign in on this device',
                      ),
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  if (_biometricAvailable) const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.password_outlined),
                    title: const Text('Change Password'),
                    subtitle: const Text(
                      'Update your account password securely',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _showChangePasswordDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Support & Legal ──────────────────────────────────────────────
            _buildSectionHeader('Support & Legal'),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/help'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('Terms & Conditions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/terms'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About SeedVest'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/about'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout Action ─────────────────────────────────────────────────
            CustomCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Sign out of your account'),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text(
                          'Are you sure you want to log out of your account?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final userViewModel = context.read<UserViewModel>();
                    await userViewModel.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }
}
