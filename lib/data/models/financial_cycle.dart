class FinancialCycle {
  final int id;
  final int groupId;
  final String groupName;
  final String cycleName;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double totalContributions;
  final double totalInvestments;
  final double totalReturns;
  final DateTime? closedAt;
  final DateTime? archivedAt;

  FinancialCycle({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.cycleName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.totalContributions,
    required this.totalInvestments,
    required this.totalReturns,
    this.closedAt,
    this.archivedAt,
  });

  factory FinancialCycle.fromJson(Map<String, dynamic> json) {
    return FinancialCycle(
      id: json['id'],
      groupId: json['group'],
      groupName: json['group_name'] ?? '',
      cycleName: json['cycle_name'] ?? '',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: json['status'] ?? 'ACTIVE',
      totalContributions:
          double.tryParse((json['total_contributions'] ?? '0').toString()) ?? 0,
      totalInvestments:
          double.tryParse((json['total_investments'] ?? '0').toString()) ?? 0,
      totalReturns:
          double.tryParse((json['total_returns'] ?? '0').toString()) ?? 0,
      closedAt:
          json['closed_at'] != null ? DateTime.tryParse(json['closed_at']) : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.tryParse(json['archived_at'])
          : null,
    );
  }
}
