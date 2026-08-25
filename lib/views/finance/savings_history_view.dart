import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_service.dart';
import '../../viewmodels/user_viewmodel.dart';

class SavingsHistoryView extends StatefulWidget {
  const SavingsHistoryView({super.key, this.memberId});

  final int? memberId;

  @override
  State<SavingsHistoryView> createState() => _SavingsHistoryViewState();
}

class _SavingsHistoryViewState extends State<SavingsHistoryView> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _entries = [];
  String _filter = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final memberId = widget.memberId ?? context.read<UserViewModel>().currentUser?.id;
    if (memberId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Member history is unavailable.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _apiService.getMemberSavingsHistory(
        memberId,
        type: _filter.isEmpty ? null : _filter,
      );
      if (!mounted) return;
      final data = response.data is List ? response.data as List : const [];
      setState(() => _entries = data.map((entry) => Map<String, dynamic>.from(entry)).toList());
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load savings history.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Savings history')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _filter,
                        decoration: const InputDecoration(labelText: 'Filter by type'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('All activity')),
                          DropdownMenuItem(value: 'contribution', child: Text('Contributions')),
                          DropdownMenuItem(value: 'penalty', child: Text('Penalties')),
                          DropdownMenuItem(value: 'investment', child: Text('Investments')),
                          DropdownMenuItem(value: 'repayment', child: Text('Repayments')),
                        ],
                        onChanged: (value) {
                          setState(() => _filter = value ?? '');
                          _loadHistory();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No financial activity found.')),
                        )
                      else
                        ..._entries.map(_entryTile),
                    ],
                  ),
                ),
    );
  }

  Widget _entryTile(Map<String, dynamic> entry) {
    final type = entry['type']?.toString() ?? 'activity';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_iconFor(type))),
        title: Text(entry['description']?.toString() ?? type),
        subtitle: Text('${entry['date'] ?? ''}  |  ${entry['status'] ?? ''}'),
        trailing: Text(
          'KES ${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'penalty':
        return Icons.warning_amber_outlined;
      case 'investment':
        return Icons.trending_up;
      case 'repayment':
        return Icons.payments_outlined;
      default:
        return Icons.savings_outlined;
    }
  }
}
