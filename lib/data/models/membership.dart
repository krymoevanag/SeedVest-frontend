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
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
}
