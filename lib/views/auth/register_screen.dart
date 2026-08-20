import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/seedvest_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _apiService = ApiService();
  List<Map<String, dynamic>> _groups = [];
  int? _selectedGroupId;
  bool _isLoadingGroups = true;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isFormValid = false;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _usernameController.addListener(_validateForm);
    _phoneController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _loadGroups();
  }

  void _validateForm() {
    final hasSelectedGroup = !_isLoadingGroups && _selectedGroupId != null;
    bool isValid =
        (_formKey.currentState?.validate() ?? false) && _termsAccepted && hasSelectedGroup;
    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  Future<void> _loadGroups() async {
    try {
      final response = await _apiService.getGroups();
      if (!mounted) return;
      if (response.statusCode == 200 && response.data is List) {
        setState(() {
          _groups = (response.data as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _isLoadingGroups = false;
        });
        _validateForm();
        return;
      }
      setState(() => _isLoadingGroups = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingGroups = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load groups right now. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter email address';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Enter phone number';
    if (!RegExp(r'^(07|01|254)\d{8}$').hasMatch(value)) {
      return 'Enter valid M-Pesa number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter password';
    if (value.length < 8) return 'Minimum 8 characters';

    // Requirements: At least one letter, one digit, and one special character
    bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(value);
    bool hasDigits = RegExp(r'\d').hasMatch(value);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasLetters || !hasDigits || !hasSpecial) {
      return 'Must include letters, numbers and special characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: _validateForm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // SeedVest Logo
                const SeedVestLogo(
                  size: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Your Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 40),

                // Full Name
                _buildFieldTitle('Full Name'),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _buildInputDecoration(
                    'Evans Kirimi',
                    Icons.person_outline,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 20),

                // Username
                _buildFieldTitle('Username'),
                TextFormField(
                  controller: _usernameController,
                  decoration: _buildInputDecoration(
                    'evans_k',
                    Icons.badge,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a username' : null,
                ),
                const SizedBox(height: 20),

                // Phone Number
                _buildFieldTitle('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration(
                    '07XXXXXXXX',
                    Icons.phone_iphone_outlined,
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 20),

                // Email Address
                _buildFieldTitle('Email Address'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration(
                    'name@example.com',
                    Icons.email_outlined,
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),

                // Preferred Group
                _buildFieldTitle('Preferred Group'),
                if (_isLoadingGroups)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_groups.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No groups available for registration right now.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedGroupId,
                    decoration: _buildInputDecoration(
                      'Select your group',
                      Icons.groups_outlined,
                    ),
                    items: _groups.map((group) {
                      return DropdownMenuItem<int>(
                        value: group['id'] as int?,
                        child: Text(group['name'] ?? 'Group ${group['id']}'),
                      );
                    }).toList(),
                    onChanged: _isLoading ? null : (value) {
                      setState(() => _selectedGroupId = value);
                      _validateForm();
                    },
                    validator: (value) =>
                        value == null ? 'Please select a group' : null,
                  ),
                const SizedBox(height: 20),

                // Password
                _buildFieldTitle('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _buildInputDecoration(
                    '••••••••',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 20),

                // Confirm Password
                _buildFieldTitle('Confirm Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _buildInputDecoration(
                    '••••••••',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Trust Message
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your membership must be approved by an administrator before account activation.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                        _validateForm();
                      },
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the '),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/terms'),
                            child: const Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Primary Button
                CustomButton(
                  text: 'CREATE ACCOUNT',
                  isLoading: _isLoading,
                        onPressed: (_isFormValid && !_isLoading)
                      ? () async {
                          setState(() => _isLoading = true);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            // Check connectivity first
                            final isConnected =
                                await _apiService.isOnline;

                            if (!isConnected) {
                              if (!mounted) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cannot connect to server. Please check your internet connection and try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                              return;
                            }

                            // Split full name into first and last name
                            final fullName = _fullNameController.text.trim();
                            final nameParts = fullName.split(' ');
                            final firstName = nameParts.first;
                            final lastName = nameParts.length > 1
                                ? nameParts.sublist(1).join(' ')
                                : '';

                            // Attempt registration
                            final response = await _apiService.register({
                              'first_name': firstName,
                              'last_name': lastName,
                              'email': _emailController.text,
                              'phone_number': _phoneController.text,
                              'password': _passwordController.text,
                              'terms_accepted': _termsAccepted,
                              'group_id': _selectedGroupId,
                              'password2': _confirmPasswordController
                                  .text, // Added password2 which is required by serializer
                            });

                            if (!mounted) return;
                            final responseData = response.data;
                            final emailSent = responseData is Map
                                ? responseData['email_sent'] != false
                                : true;
                            final message = responseData is Map &&
                                    responseData['message'] != null
                                ? responseData['message'].toString()
                                : emailSent
                                    ? 'Registration successful! Check your email to activate your account, then await admin approval.'
                                    : 'Registration submitted, but the activation email could not be delivered. Please contact support.';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor:
                                    emailSent ? Colors.green : Colors.orange,
                              ),
                            );
                            Navigator.pushReplacementNamed(
                                this.context, '/activation-waiting');
                          } catch (e) {
                            if (!mounted) return;
                            String errorMessage =
                                'Registration failed. Please try again.';

                            if (e is DioException) {
                              if (e.type == DioExceptionType.connectionTimeout ||
                                  e.type == DioExceptionType.receiveTimeout ||
                                  e.type == DioExceptionType.sendTimeout ||
                                  e.type == DioExceptionType.connectionError) {
                                errorMessage =
                                    "Unable to connect to server. Please check your internet connection.";
                              } else if (e.response?.data != null) {
                                final data = e.response?.data;
                                if (data is Map) {
                                  if (data.containsKey('username')) {
                                    errorMessage = 'Username already exists.';
                                  } else if (data.containsKey('email')) {
                                    errorMessage = 'Email already registered.';
                                  } else if (data.containsKey('password')) {
                                    final passwordErrors = data['password'];
                                    if (passwordErrors is List) {
                                      errorMessage = passwordErrors.join('\n');
                                    } else {
                                      errorMessage = passwordErrors.toString();
                                    }
                                  } else if (data.containsKey('terms_accepted')) {
                                    errorMessage =
                                        'You must accept the Terms & Conditions.';
                                  } else if (data.containsKey('detail')) {
                                    errorMessage = data['detail'].toString();
                                  } else if (data.containsKey('group_id')) {
                                    final groupError = data['group_id'];
                                    if (groupError is List) {
                                      errorMessage = groupError.join('\n');
                                    } else {
                                      errorMessage = groupError.toString();
                                    }
                                  } else {
                                    errorMessage = data.values.join('\n');
                                  }
                                }
                              } else {
                                errorMessage =
                                    'Server error: ${e.response?.statusCode ?? "Unknown"}';
                              }
                            }

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildFieldTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
            color: AppColors.secondary, width: 2), // Royal Blue active
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
