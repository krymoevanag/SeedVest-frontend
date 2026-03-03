class Contribution {
  final int id;
  final int userId;
  final int groupId;
  final int? financialCycleId;
  final double amount;
  final double expectedAmount;
  final double penalty;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final DateTime? contributionMonth;
  final DateTime date;
  final String status;
  final bool isManualEntry;
  final DateTime? reportedPaidDate;
  final String? reportedPaymentMethod;
  final String? reportedReference;
  final String? reportedNote;
  final String? rejectionReason;
  final bool isLocked;
  final DateTime? reviewedAt;
  final String? transactionId;

  Contribution({
    required this.id,
    required this.userId,
    required this.groupId,
    this.financialCycleId,
    required this.amount,
    this.expectedAmount = 0,
    this.penalty = 0,
    this.dueDate,
    this.paidDate,
    this.contributionMonth,
    required this.date,
    required this.status,
    required this.isManualEntry,
    this.reportedPaidDate,
    this.reportedPaymentMethod,
    this.reportedReference,
    this.reportedNote,
    this.rejectionReason,
    this.isLocked = false,
    this.reviewedAt,
    this.transactionId,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      userId: json['user'],
      groupId: json['group'] ?? 0,
      financialCycleId: json['financial_cycle'],
      amount: double.parse(json['amount'].toString()),
      expectedAmount:
          double.tryParse((json['expected_amount'] ?? '0').toString()) ?? 0,
      penalty: double.tryParse((json['penalty'] ?? '0').toString()) ?? 0,
      dueDate:
          json['due_date'] != null ? DateTime.tryParse(json['due_date']) : null,
      paidDate:
          json['paid_date'] != null ? DateTime.tryParse(json['paid_date']) : null,
      contributionMonth: json['contribution_month'] != null
          ? DateTime.tryParse(json['contribution_month'])
          : null,
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      isManualEntry: json['is_manual_entry'] ?? false,
      reportedPaidDate: json['reported_paid_date'] != null
          ? DateTime.tryParse(json['reported_paid_date'])
          : null,
      reportedPaymentMethod: json['reported_payment_method'],
      reportedReference: json['reported_reference'],
      reportedNote: json['reported_note'],
      rejectionReason: json['rejection_reason'],
      isLocked: json['is_locked'] ?? false,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'])
          : null,
      transactionId: json['transaction_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'group': groupId,
      'financial_cycle': financialCycleId,
      'amount': amount,
      'expected_amount': expectedAmount,
      'penalty': penalty,
      'due_date': dueDate?.toIso8601String().split('T')[0],
      'paid_date': paidDate?.toIso8601String().split('T')[0],
      'contribution_month': contributionMonth?.toIso8601String().split('T')[0],
      'created_at': date.toIso8601String(),
      'status': status,
      'is_manual_entry': isManualEntry,
      'reported_paid_date': reportedPaidDate?.toIso8601String(),
      'reported_payment_method': reportedPaymentMethod,
      'reported_reference': reportedReference,
      'reported_note': reportedNote,
      'rejection_reason': rejectionReason,
      'is_locked': isLocked,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'transaction_id': transactionId,
    };
  }
}
