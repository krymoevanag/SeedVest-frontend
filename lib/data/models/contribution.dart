class Contribution {
  final int id;
  final int userId;
  final int groupId;
  final double amount;
  final DateTime date;
  final String status;
  final bool isManualEntry;
  final DateTime? reportedPaidDate;
  final String? reportedPaymentMethod;
  final String? reportedReference;
  final String? reportedNote;
  final DateTime? reviewedAt;
  final String? transactionId;

  Contribution({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.amount,
    required this.date,
    required this.status,
    required this.isManualEntry,
    this.reportedPaidDate,
    this.reportedPaymentMethod,
    this.reportedReference,
    this.reportedNote,
    this.reviewedAt,
    this.transactionId,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      userId: json['user'],
      groupId: json['group'] ?? 0,
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      isManualEntry: json['is_manual_entry'] ?? false,
      reportedPaidDate: json['reported_paid_date'] != null
          ? DateTime.tryParse(json['reported_paid_date'])
          : null,
      reportedPaymentMethod: json['reported_payment_method'],
      reportedReference: json['reported_reference'],
      reportedNote: json['reported_note'],
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
      'amount': amount,
      'created_at': date.toIso8601String(),
      'status': status,
      'is_manual_entry': isManualEntry,
      'reported_paid_date': reportedPaidDate?.toIso8601String(),
      'reported_payment_method': reportedPaymentMethod,
      'reported_reference': reportedReference,
      'reported_note': reportedNote,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'transaction_id': transactionId,
    };
  }
}
