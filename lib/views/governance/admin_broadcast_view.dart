import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/api_service.dart';
import '../../data/models/user.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../widgets/custom_button.dart';

class AdminBroadcastView extends StatefulWidget {
  const AdminBroadcastView({super.key});

  @override
  State<AdminBroadcastView> createState() => _AdminBroadcastViewState();
}

class _AdminBroadcastViewState extends State<AdminBroadcastView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'INFO';
  bool _isBroadcast = true;

  List<User> _members = [];
  User? _selectedMember;
  bool _isLoadingMembers = false;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });

    try {
      final response = await ApiService().getUsers(approvedOnly: true);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final users = data.map((json) => User.fromJson(json)).toList();
        if (mounted) {
          setState(() {
            _members = users;
            _isLoadingMembers = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMembers = false;
            _membersError = 'Failed to load member list';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMembers = false;
          _membersError = 'Error loading members: $e';
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isBroadcast && _selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient member'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final viewModel = context.read<NotificationViewModel>();
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    bool success;
    if (_isBroadcast) {
      success = await viewModel.sendBroadcast(
        title: title,
        message: message,
        type: _selectedType,
      );
    } else {
      success = await viewModel.sendDirectNotification(
        recipientId: _selectedMember!.id,
        title: title,
        message: message,
        type: _selectedType,
      );
    }

    if (mounted) {
      if (success) {
        final successMsg = _isBroadcast
            ? 'Broadcast sent successfully'
            : 'Notification sent to ${_selectedMember?.fullName ?? "member"} successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send announcements or direct alerts to group members.',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Target Audience Selector
              const Text(
                'Audience Target',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('All Members (Broadcast)')),
                      selected: _isBroadcast,
                      onSelected: (selected) {
                        if (selected) setState(() => _isBroadcast = true);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Specific Member')),
                      selected: !_isBroadcast,
                      onSelected: (selected) {
                        if (selected) setState(() => _isBroadcast = false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Individual Member Dropdown (visible when !_isBroadcast)
              if (!_isBroadcast) ...[
                if (_isLoadingMembers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading active members...'),
                      ],
                    ),
                  )
                else if (_membersError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _membersError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadMembers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<User>(
                    initialValue: _selectedMember,
                    decoration: const InputDecoration(
                      labelText: 'Select Recipient Member',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: _members.map((member) {
                      final name = member.fullName.isNotEmpty
                          ? member.fullName
                          : member.email;
                      final role = member.role;
                      return DropdownMenuItem<User>(
                        value: member,
                        child: Text(
                          '$name ($role)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMember = val),
                    validator: (val) {
                      if (!_isBroadcast && val == null) {
                        return 'Please select a recipient';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 20),
              ],

              // Notification Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Notification Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'INFO', child: Text('Information')),
                  DropdownMenuItem(value: 'SUCCESS', child: Text('Success')),
                  DropdownMenuItem(value: 'WARNING', child: Text('Warning')),
                  DropdownMenuItem(value: 'ERROR', child: Text('Alert/Error')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  hintText: 'e.g. Monthly Meeting Reminder',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Subject is required' : null,
              ),
              const SizedBox(height: 20),

              // Message Body Field
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  hintText: 'Enter your message here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Message body is required' : null,
              ),
              const SizedBox(height: 36),

              // Submit Button
              Selector<NotificationViewModel, bool>(
                selector: (_, vm) => vm.isLoading,
                builder: (context, isLoading, child) {
                  return CustomButton(
                    text: _isBroadcast ? 'Send Broadcast' : 'Send to Member',
                    onPressed: isLoading ? null : _sendNotification,
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
