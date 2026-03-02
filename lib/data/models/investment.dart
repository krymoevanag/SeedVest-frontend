class Investment {
  final int id;
  final String name;
  final String description;
  final String category;
  final String purpose;
  final String? businessCase;
  final String? attachment;
  final double amountInvested;
  final String currency;
  final double expectedRoiPercentage;
  final String returnType;
  final int? duration;
  final String payoutFrequency;
  final double? minCapital;
  final String riskLevel;
  final int? lockInPeriod;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String? groupName;
  final String? createdByEmail;
  final DateTime createdAt;

  Investment({
    required this.id,
    required this.name,
    required this.description,
    this.category = '',
    this.purpose = '',
    this.businessCase,
    this.attachment,
    required this.amountInvested,
    this.currency = 'KES',
    required this.expectedRoiPercentage,
    this.returnType = 'FIXED',
    this.duration,
    this.payoutFrequency = 'AT_MATURITY',
    this.minCapital,
    this.riskLevel = 'MEDIUM',
    this.lockInPeriod,
    required this.status,
    required this.startDate,
    this.endDate,
    this.groupName,
    this.createdByEmail,
    required this.createdAt,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      purpose: json['purpose'] ?? '',
      businessCase: json['business_case'],
      attachment: json['attachment'],
      amountInvested:
          double.tryParse(json['amount_invested']?.toString() ?? '0') ?? 0,
      currency: json['currency'] ?? 'KES',
      expectedRoiPercentage:
          double.tryParse(json['expected_roi_percentage']?.toString() ?? '0') ??
              0,
      returnType: json['return_type'] ?? 'FIXED',
      duration: json['duration'],
      payoutFrequency: json['payout_frequency'] ?? 'AT_MATURITY',
      minCapital: json['min_capital'] != null
          ? double.tryParse(json['min_capital'].toString())
          : null,
      riskLevel: json['risk_level'] ?? 'MEDIUM',
      lockInPeriod: json['lock_in_period'],
      status: json['status'] ?? 'PENDING_APPROVAL',
      startDate: DateTime.parse(json['start_date']),
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      groupName: json['group_name'],
      createdByEmail: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'purpose': purpose,
      'business_case': businessCase,
      'attachment': attachment,
      'amount_invested': amountInvested,
      'currency': currency,
      'expected_roi_percentage': expectedRoiPercentage,
      'return_type': returnType,
      'duration': duration,
      'payout_frequency': payoutFrequency,
      'min_capital': minCapital,
      'risk_level': riskLevel,
      'lock_in_period': lockInPeriod,
      'status': status,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}
