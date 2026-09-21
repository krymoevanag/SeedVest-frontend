import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/colors.dart';
import '../../viewmodels/user_viewmodel.dart';

class SavingsHistoryView extends StatefulWidget {
  const SavingsHistoryView({super.key, this.memberId});

  final int? memberId;

  @override
  State<SavingsHistoryView> createState() => _SavingsHistoryViewState();
}

class _SavingsHistoryViewState extends State<SavingsHistoryView> {
  final ApiService _apiService = ApiService();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'KES ');
  final DateFormat _dateLabel = DateFormat('MMM dd, yyyy');

  List<Map<String, dynamic>> _entries = [];
  String _filter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final memberId =
        widget.memberId ?? context.read<UserViewModel>().currentUser?.id;
    if (memberId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Financial history is unavailable.';
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
        startDate: _startDate,
        endDate: _endDate,
        type: _filter.isEmpty ? null : _filter,
      );
      if (!mounted) return;
      final data = response.data is List ? response.data as List : const [];
      setState(() =>
          _entries = data.map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load financial history.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalAmount =>
      _entries.fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? now.subtract(const Duration(days: 90)))
          : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
    _loadHistory();
  }

  void _clearFilters() {
    setState(() {
      _filter = '';
      _startDate = null;
      _endDate = null;
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        _filter.isNotEmpty || _startDate != null || _endDate != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial History'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear',
                  style: TextStyle(color: Colors.orange, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 52, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // ── Filter bar ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: _FilterBar(
                          filter: _filter,
                          startDate: _startDate,
                          endDate: _endDate,
                          dateLabel: _dateLabel,
                          onFilterChanged: (v) {
                            setState(() => _filter = v);
                            _loadHistory();
                          },
                          onPickStart: () => _pickDate(isStart: true),
                          onPickEnd: () => _pickDate(isStart: false),
                        ),
                      ),

                      // ── Summary bar ────────────────────────────────────
                      if (_entries.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _SummaryBar(
                            total: _totalAmount,
                            count: _entries.length,
                            currency: _currency,
                          ),
                        ),

                      // ── Entry list ─────────────────────────────────────
                      if (_entries.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 14),
                                Text(
                                  'No financial activity found.',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 15),
                                ),
                                if (hasFilters) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _clearFilters,
                                    child: const Text('Clear filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = _entries[index];
                                // Date section header
                                final entryDate =
                                    entry['date']?.toString() ?? '';
                                final prevDate = index > 0
                                    ? _entries[index - 1]['date']
                                            ?.toString() ??
                                        ''
                                    : '';
                                final showHeader =
                                    index == 0 || entryDate != prevDate;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (showHeader) ...[
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4, bottom: 8),
                                        child: Text(
                                          _formatDateHeader(entryDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                    _EntryCard(
                                        entry: entry, currency: _currency),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                              childCount: _entries.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  String _formatDateHeader(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}

// ── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.startDate,
    required this.endDate,
    required this.dateLabel,
    required this.onFilterChanged,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final String filter;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateFormat dateLabel;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChip(
                    label: 'All',
                    selected: filter.isEmpty,
                    onTap: () => onFilterChanged('')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Contributions',
                    selected: filter == 'contribution',
                    color: const Color(0xFF43A047),
                    onTap: () => onFilterChanged('contribution')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Penalties',
                    selected: filter == 'penalty',
                    color: const Color(0xFFE53935),
                    onTap: () => onFilterChanged('penalty')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Investments',
                    selected: filter == 'investment',
                    color: const Color(0xFF1E88E5),
                    onTap: () => onFilterChanged('investment')),
                const SizedBox(width: 8),
                _TypeChip(
                    label: 'Loan Repayments',
                    selected: filter == 'repayment',
                    color: const Color(0xFF4A148C),
                    onTap: () => onFilterChanged('repayment')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Date pickers
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: startDate != null
                      ? dateLabel.format(startDate!)
                      : 'From date',
                  icon: Icons.date_range,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateButton(
                  label: endDate != null
                      ? dateLabel.format(endDate!)
                      : 'To date',
                  icon: Icons.date_range,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? activeColor
                  : Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary bar ──────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar(
      {required this.total, required this.count, required this.currency});

  final double total;
  final int count;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count transaction${count == 1 ? '' : 's'}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary),
          ),
          Text(
            currency.format(total),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Entry card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.currency});

  final Map<String, dynamic> entry;
  final NumberFormat currency;

  static const _typeConfig = {
    'contribution': (
      icon: Icons.savings_outlined,
      gradient: [Color(0xFF1B5E20), Color(0xFF43A047)],
      label: 'Contribution',
    ),
    'penalty': (
      icon: Icons.gavel_outlined,
      gradient: [Color(0xFFB71C1C), Color(0xFFE57373)],
      label: 'Penalty',
    ),
    'investment': (
      icon: Icons.trending_up,
      gradient: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
      label: 'Investment',
    ),
    'repayment': (
      icon: Icons.payments_outlined,
      gradient: [Color(0xFF4A148C), Color(0xFFAB47BC)],
      label: 'Repayment',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final type = entry['type']?.toString() ?? 'contribution';
    final config = _typeConfig[type] ??
        (
          icon: Icons.receipt_outlined,
          gradient: [const Color(0xFF455A64), const Color(0xFF78909C)],
          label: 'Activity',
        );
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final status = entry['status']?.toString() ?? '';
    final description =
        entry['description']?.toString() ?? config.label;
    final dateStr = entry['date']?.toString() ?? '';

    String formattedDate = dateStr;
    try {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (_) {}

    return InkWell(
      onTap: () => _showDetailModal(context, config, formattedDate, amount, status, description),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Coloured left strip + icon
            Container(
              width: 52,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: config.gradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
              ),
              child: Icon(config.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),

            // Description + date + status
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(status)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: _statusColor(status)),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Amount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                currency.format(amount),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: config.gradient.first,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(
    BuildContext context,
    dynamic config,
    String formattedDate,
    double amount,
    String status,
    String description,
  ) {
    final reference = entry['reference']?.toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: config.gradient),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: config.gradient.first,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _detailRow('Description', description),
            if (status.isNotEmpty) _detailRow('Status', status),
            if (reference != null && reference.isNotEmpty)
              _detailRow('Transaction Ref', reference),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
      case 'VERIFIED':
      case 'APPROVED':
      case 'ACTIVE':
      case 'MATURED':
        return AppColors.success;
      case 'LATE':
        return AppColors.warning;
      case 'UNPAID':
      case 'OVERDUE':
      case 'REJECTED':
      case 'DEFAULTED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
