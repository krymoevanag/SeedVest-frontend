class LoanGuarantor {
  final int id;
  final int loanId;
  final int guarantorUserId;
  final String guarantorName;
  final String guarantorEmail;
  final double amountGuaranteed;
  final String status;
  final String responseNotes;
  final DateTime? respondedAt;

  const LoanGuarantor({
    required this.id,
    required this.loanId,
    required this.guarantorUserId,
    required this.guarantorName,
    required this.guarantorEmail,
    required this.amountGuaranteed,
    required this.status,
    required this.responseNotes,
    this.respondedAt,
  });

  factory LoanGuarantor.fromJson(Map<String, dynamic> json) {
    return LoanGuarantor(
      id: json['id'] as int,
      loanId: json['loan'] as int,
      guarantorUserId: json['guarantor_user'] as int,
      guarantorName: json['guarantor_name']?.toString() ?? '',
      guarantorEmail: json['guarantor_email']?.toString() ?? '',
      amountGuaranteed: _asDouble(json['amount_guaranteed']),
      status: json['status']?.toString() ?? 'PENDING',
      responseNotes: json['response_notes']?.toString() ?? '',
      respondedAt: _asDate(json['responded_at']),
    );
  }
}

class LoanRepayment {
  final int id;
  final int loanId;
  final int userId;
  final String userName;
  final double amount;
  final String paymentMethod;
  final String transactionReference;
  final String notes;
  final String status;
  final String? verifiedByName;
  final DateTime? verifiedAt;
  final DateTime paidAt;

  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.paymentMethod,
    required this.transactionReference,
    required this.notes,
    required this.status,
    this.verifiedByName,
    this.verifiedAt,
    required this.paidAt,
  });

  factory LoanRepayment.fromJson(Map<String, dynamic> json) {
    return LoanRepayment(
      id: json['id'] as int,
      loanId: json['loan'] as int,
      userId: json['user'] as int,
      userName: json['user_name']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      paymentMethod: json['payment_method']?.toString() ?? 'MPESA',
      transactionReference: json['transaction_reference']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      verifiedByName: json['verified_by_name']?.toString(),
      verifiedAt: _asDate(json['verified_at']),
      paidAt: _asDate(json['paid_at']) ?? DateTime.now(),
    );
  }
}

class LoanInstallment {
  final int id;
  final int loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double totalDue;
  final String status;
  final DateTime? paidDate;

  const LoanInstallment({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.totalDue,
    required this.status,
    this.paidDate,
  });

  factory LoanInstallment.fromJson(Map<String, dynamic> json) {
    return LoanInstallment(
      id: json['id'] as int,
      loanId: json['loan'] as int,
      installmentNumber: (json['installment_number'] as num).toInt(),
      dueDate: _asDate(json['due_date']) ?? DateTime.now(),
      principalAmount: _asDouble(json['principal_amount']),
      interestAmount: _asDouble(json['interest_amount']),
      totalDue: _asDouble(json['total_due']),
      status: json['status']?.toString() ?? 'PENDING',
      paidDate: _asDate(json['paid_date']),
    );
  }
}

class Loan {
  final int id;
  final int userId;
  final String borrowerName;
  final int groupId;
  final String groupName;
  final int? financialCycleId;
  final double amount;
  final double interestRate;
  final int durationMonths;
  final double totalPayable;
  final double balanceRemaining;
  final String purpose;
  final String status;
  final String rejectionReason;
  final DateTime? approvedAt;
  final DateTime? disbursedAt;
  final DateTime? dueDate;
  final DateTime createdAt;
  final List<LoanGuarantor> guarantors;
  final List<LoanRepayment> repayments;
  final List<LoanInstallment> installments;

  const Loan({
    required this.id,
    required this.userId,
    required this.borrowerName,
    required this.groupId,
    required this.groupName,
    this.financialCycleId,
    required this.amount,
    required this.interestRate,
    required this.durationMonths,
    required this.totalPayable,
    required this.balanceRemaining,
    required this.purpose,
    required this.status,
    required this.rejectionReason,
    this.approvedAt,
    this.disbursedAt,
    this.dueDate,
    required this.createdAt,
    required this.guarantors,
    required this.repayments,
    required this.installments,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    List<dynamic> valuesFor(String key) {
      final value = json[key];
      return value is List ? value : const [];
    }

    return Loan(
      id: json['id'] as int,
      userId: json['user'] as int,
      borrowerName: json['borrower_name']?.toString() ?? '',
      groupId: json['group'] as int,
      groupName: json['group_name']?.toString() ?? '',
      financialCycleId: json['financial_cycle'] as int?,
      amount: _asDouble(json['amount']),
      interestRate: _asDouble(json['interest_rate']),
      durationMonths: (json['duration_months'] as num?)?.toInt() ?? 1,
      totalPayable: _asDouble(json['total_payable']),
      balanceRemaining: _asDouble(json['balance_remaining']),
      purpose: json['purpose']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING_GUARANTORS',
      rejectionReason: json['rejection_reason']?.toString() ?? '',
      approvedAt: _asDate(json['approved_at']),
      disbursedAt: _asDate(json['disbursed_at']),
      dueDate: _asDate(json['due_date']),
      createdAt: _asDate(json['created_at']) ?? DateTime.now(),
      guarantors: valuesFor('guarantors')
          .map((item) =>
              LoanGuarantor.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      repayments: valuesFor('repayments')
          .map((item) =>
              LoanRepayment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      installments: valuesFor('installments')
          .map((item) =>
              LoanInstallment.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  bool isGuarantor(int userId) =>
      guarantors.any((guarantor) => guarantor.guarantorUserId == userId);
}

double _asDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0.0;

DateTime? _asDate(dynamic value) =>
    value == null ? null : DateTime.tryParse(value.toString());
