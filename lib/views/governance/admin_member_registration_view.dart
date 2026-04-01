import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/governance_viewmodel.dart';
import '../../core/theme/colors.dart';
import '../widgets/custom_button.dart';

class AdminMemberRegistrationView extends StatefulWidget {
  const AdminMemberRegistrationView({super.key});

  @override
  State<AdminMemberRegistrationView> createState() =>
      _AdminMemberRegistrationViewState();
}

class _AdminMemberRegistrationViewState
    extends State<AdminMemberRegistrationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'MEMBER';
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GovernanceViewModel>().fetchGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerMember() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = context.read<GovernanceViewModel>();
    final success = await viewModel.registerMember(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      role: _selectedRole,
      groupId: _selectedGroupId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member registered successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to register member. Email may already exist.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Member'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Register a new member manually. They will be auto-approved and notified.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Full name is required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Email is required';
                  if (!val.contains('@')) return 'Invalid email address';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: '2547XXXXXXXX',
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Phone number is required'
                    : null,
              ),
              const SizedBox(height: 20),
              
              // Group Selection
              Consumer<GovernanceViewModel>(
                builder: (context, vm, child) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Group (Mandatory)',
                      prefixIcon: Icon(Icons.group_outlined),
                    ),
                    items: vm.groups.map<DropdownMenuItem<int>>((group) {
                      return DropdownMenuItem<int>(
                        value: group['id'],
                        child: Text(group['name']),
                      );
                    }).toList(),
                    validator: (val) => val == null ? 'Group assignment is required' : null,
                    onChanged: (val) => setState(() => _selectedGroupId = val),
                    hint: const Text('Select a group'),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Initial Role',
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'MEMBER', child: Text('Member')),
                  DropdownMenuItem(
                      value: 'TREASURER', child: Text('Treasurer')),
                  DropdownMenuItem(
                      value: 'FINANCIAL_SECRETARY',
                      child: Text('Financial Secretary')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 48),
              Selector<GovernanceViewModel, bool>(
                selector: (_, vm) => vm.isLoading,
                builder: (context, isLoading, child) {
                  return CustomButton(
                    text: 'Register Member',
                    onPressed: isLoading ? null : _registerMember,
                    isLoading: isLoading,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
