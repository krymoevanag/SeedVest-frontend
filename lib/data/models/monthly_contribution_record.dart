class MonthlyContributionRecord {
  final int id;
  final int userId;
  final String memberName;
  final int groupId;
  final String groupName;
  final int financialCycleId;
  final String cycleName;
  final DateTime month;
  final double expectedContributionAmount;
  final double actualContributionPaid;
  final DateTime? paymentDate;
  final double outstandingAmount;
  final String status;

  MonthlyContributionRecord({
    required this.id,
    required this.userId,
    required this.memberName,
    required this.groupId,
    required this.groupName,
    required this.financialCycleId,
    required this.cycleName,
    required this.month,
    required this.expectedContributionAmount,
    required this.actualContributionPaid,
    this.paymentDate,
    required this.outstandingAmount,
    required this.status,
  });

  factory MonthlyContributionRecord.fromJson(Map<String, dynamic> json) {
    return MonthlyContributionRecord(
      id: json['id'],
      userId: json['user'],
      memberName: json['member_name'] ?? '',
      groupId: json['group'],
      groupName: json['group_name'] ?? '',
      financialCycleId: json['financial_cycle'],
      cycleName: json['cycle_name'] ?? '',
      month: DateTime.parse(json['month']),
      expectedContributionAmount: double.tryParse(
            (json['expected_contribution_amount'] ?? '0').toString(),
          ) ??
          0,
      actualContributionPaid:
          double.tryParse((json['actual_contribution_paid'] ?? '0').toString()) ??
              0,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'])
          : null,
      outstandingAmount:
          double.tryParse((json['outstanding_amount'] ?? '0').toString()) ?? 0,
      status: json['status'] ?? 'UNPAID',
    );
  }
}
