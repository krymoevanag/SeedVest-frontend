class Membership {
  final int id;
  final int userId;
  final String fullName;
  final String email;
  final String? membershipNumber;
  final int groupId;
  final String groupName;
  final String role;
  final double savingsBalance;
  final double penaltiesBalance;
  final int totalContributionsCount;
  final int paidContributionsCount;
  final int pendingContributionsCount;
  final int overdueContributionsCount;
  final int rejectedContributionsCount;
  final double expectedTotal;
  final double outstandingTotal;
  final DateTime? lastContributionDate;
  final double lastContributionAmount;
  final DateTime joinedAt;

  Membership({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.membershipNumber,
    required this.groupId,
    required this.groupName,
    required this.role,
    required this.savingsBalance,
    required this.penaltiesBalance,
    required this.totalContributionsCount,
    required this.paidContributionsCount,
    required this.pendingContributionsCount,
    required this.overdueContributionsCount,
    required this.rejectedContributionsCount,
    required this.expectedTotal,
    required this.outstandingTotal,
    this.lastContributionDate,
    required this.lastContributionAmount,
    required this.joinedAt,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(
      id: json['id'],
      userId: json['user_id'],
      fullName: json['full_name'],
      email: json['email'],
      membershipNumber: json['membership_number'],
      groupId: json['group_id'],
      groupName: json['group_name'],
      role: json['role'],
      savingsBalance:
          double.tryParse(json['savings_balance'].toString()) ?? 0.0,
      penaltiesBalance:
          double.tryParse(json['penalties_balance'].toString()) ?? 0.0,
      totalContributionsCount: json['total_contributions_count'] ?? 0,
      paidContributionsCount: json['paid_contributions_count'] ?? 0,
      pendingContributionsCount: json['pending_contributions_count'] ?? 0,
      overdueContributionsCount: json['overdue_contributions_count'] ?? 0,
      rejectedContributionsCount: json['rejected_contributions_count'] ?? 0,
      expectedTotal: double.tryParse(json['expected_total'].toString()) ?? 0.0,
      outstandingTotal:
          double.tryParse(json['outstanding_total'].toString()) ?? 0.0,
      lastContributionDate: json['last_contribution_date'] != null
          ? DateTime.tryParse(json['last_contribution_date'].toString())
          : null,
      lastContributionAmount:
          double.tryParse(json['last_contribution_amount'].toString()) ?? 0.0,
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
}
