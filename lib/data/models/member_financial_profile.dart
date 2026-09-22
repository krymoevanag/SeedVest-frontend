class MemberProfileInfo {
  final int id;
  final String name;
  final String email;
  final String? membershipNumber;

  MemberProfileInfo({
    required this.id,
    required this.name,
    required this.email,
    this.membershipNumber,
  });

  factory MemberProfileInfo.fromJson(Map<String, dynamic> json) {
    return MemberProfileInfo(
      id: json['id'] is num ? (json['id'] as num).toInt() : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      membershipNumber: json['membership_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'membership_number': membershipNumber,
    };
  }
}

class MemberFinancialProfile {
  final MemberProfileInfo member;
  final double totalSavings;
  final double totalContributions;
  final double totalPenalties;
  final double totalInvestments;
  final int activeLoans;
  final double outstandingBalance;
  final int overdueLoans;
  final double overdueBalance;
  final double totalRepayments;
  final double netPosition;

  MemberFinancialProfile({
    required this.member,
    required this.totalSavings,
    required this.totalContributions,
    required this.totalPenalties,
    required this.totalInvestments,
    required this.activeLoans,
    required this.outstandingBalance,
    required this.overdueLoans,
    required this.overdueBalance,
    required this.totalRepayments,
    required this.netPosition,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory MemberFinancialProfile.fromJson(Map<String, dynamic> json) {
    final memberData = json['member'];
    final memberInfo = memberData is Map<String, dynamic>
        ? MemberProfileInfo.fromJson(memberData)
        : (memberData is Map
            ? MemberProfileInfo.fromJson(Map<String, dynamic>.from(memberData))
            : MemberProfileInfo(id: 0, name: '', email: ''));

    return MemberFinancialProfile(
      member: memberInfo,
      totalSavings: _toDouble(json['total_savings']),
      totalContributions: _toDouble(json['total_contributions']),
      totalPenalties: _toDouble(json['total_penalties']),
      totalInvestments: _toDouble(json['total_investments']),
      activeLoans: _toInt(json['active_loans']),
      outstandingBalance: _toDouble(json['outstanding_balance']),
      overdueLoans: _toInt(json['overdue_loans']),
      overdueBalance: _toDouble(json['overdue_balance']),
      totalRepayments: _toDouble(json['total_repayments']),
      netPosition: _toDouble(json['net_position']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'member': member.toJson(),
      'total_savings': totalSavings,
      'total_contributions': totalContributions,
      'total_penalties': totalPenalties,
      'total_investments': totalInvestments,
      'active_loans': activeLoans,
      'outstanding_balance': outstandingBalance,
      'overdue_loans': overdueLoans,
      'overdue_balance': overdueBalance,
      'total_repayments': totalRepayments,
      'net_position': netPosition,
    };
  }
}
