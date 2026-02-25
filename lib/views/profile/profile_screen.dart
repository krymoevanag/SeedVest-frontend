import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/network/api_service.dart';
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
  bool _isEditing = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final BiometricService _biometricService = BiometricService();
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricLabel = 'Biometrics';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserViewModel>().currentUser;
    // Split full name potentially, but better if we had separate fields in User model.
    // For now, assuming User model has fullName, we might just edit phone number
    // or if we updated User model to have first/last name.
    // Let's check User model... it has fullName.
    // Backend serializer has first_name, last_name.
    // We should treat fullName as read-only or split it?
    // Let's just allow editing Phone Number for now to be safe,
    // or try to split the name.

    // Actually, let's look at the User model in Flutter.
    // It has `fullName`.
    // We can try to split it for the controller, but when saving we need to send first_name/last_name.
    // Let's just add fields for First/Last Name to the Flutter User model to make this clean.
    // But for now, to avoid breaking changes, let's just use empty strings or try to parse.

    var names = (user?.fullName ?? '').split(' ');
    String first = names.isNotEmpty ? names.first : '';
    String last = names.length > 1 ? names.sublist(1).join(' ') : '';

    _firstNameController = TextEditingController(text: first);
    _lastNameController = TextEditingController(text: last);
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _loadBiometricSettings();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    final canAuthenticate = await _biometricService.canAuthenticate();
    final enabled = await _apiService.isBiometricEnabled();
    final label = await _biometricService.biometricLabel();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = canAuthenticate;
      _biometricEnabled = enabled;
      _biometricLabel = label;
    });
  }

  Future<void> _toggleBiometric(bool enabled) async {
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

    await _apiService.setBiometricEnabled(enabled);
    if (!mounted) return;
    setState(() => _biometricEnabled = enabled);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Biometric login enabled.'
              : 'Biometric login disabled.',
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Check file size (1MB limit)
      final file = File(pickedFile.path);
      final bytes = await file.length();
      if (bytes > 1 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image size must be less than 1MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _imageFile = file;
      });

      // Automatically upload
      if (mounted) {
        final success = await context
            .read<UserViewModel>()
            .updateProfilePicture(pickedFile.path);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final user = userViewModel.currentUser;
    final isLoading = userViewModel.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Cancel editing, reset fields
                  var names = (user?.fullName ?? '').split(' ');
                  _firstNameController.text =
                      names.isNotEmpty ? names.first : '';
                  _lastNameController.text =
                      names.length > 1 ? names.sublist(1).join(' ') : '';
                  _phoneController.text = user?.phoneNumber ?? '';
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
            // Profile Header
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
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
                                    fontSize: 40,
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
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Icon(
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
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'User',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),

            // Info Details
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
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          enabled: _isEditing,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          enabled: _isEditing,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Account Details'),
                  CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildReadOnlyField(
                            'Email', user?.email ?? '', Icons.email_outlined),
                        const Divider(),
                        _buildReadOnlyField(
                            'Membership No.',
                            user?.membershipNumber ?? 'Pending',
                            Icons
                                .card_membership), // Need to add membershipNumber to User model in Flutter
                        const Divider(),
                        _buildReadOnlyField(
                            'Role', user?.role ?? 'Member', Icons.security),
                        const Divider(),
                        _buildReadOnlyField(
                            'Status',
                            user?.isApproved == true
                                ? 'Active'
                                : 'Pending Approval',
                            Icons.info_outline),
                      ],
                    ),
                  ),
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Security'),
                    CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Enable $_biometricLabel Login'),
                        subtitle: const Text(
                          'Use biometrics for faster sign in on this device',
                        ),
                        value: _biometricEnabled,
                        onChanged: _toggleBiometric,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildSectionHeader('Support & Legal'),
                  CustomCard(
                    padding: const EdgeInsets.all(0),
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
                          title: const Text('About Us'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, '/about'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (_isEditing)
              CustomButton(
                text: 'Save Changes',
                isLoading: isLoading,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final success = await userViewModel.updateProfile({
                      'first_name': _firstNameController.text,
                      'last_name': _lastNameController.text,
                      'phone_number': _phoneController.text,
                    });

                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated successfully!')),
                      );
                      setState(() => _isEditing = false);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Failed to update profile. Please try again.'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),

            if (!_isEditing) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: 'Logout',
                backgroundColor: Colors.red.shade50,
                textColor: Colors.red,
                isLoading: false,
                onPressed: () async {
                  final userViewModel = context.read<UserViewModel>();
                  await userViewModel.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _showDeleteAccountDialog,
                child: const Text(
                  'Delete Account',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final userViewModel = context.read<UserViewModel>();
              final success = await userViewModel.deleteAccount();
              if (!mounted) return;
              if (success) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully.')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete account. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.textSecondary,
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
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: enabled ? const OutlineInputBorder() : InputBorder.none,
        contentPadding: enabled ? null : const EdgeInsets.all(0),
        filled: enabled,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
