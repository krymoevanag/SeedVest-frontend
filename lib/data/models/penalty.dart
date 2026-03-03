class Penalty {
  final int id;
  final int? userId;
  final String? userName;
  final int? contributionId;
  final String? groupName;
  final int? appliedById;
  final double amount;
  final String reason;
  final DateTime date;
  final String status;

  Penalty({
    required this.id,
    required this.userId,
    required this.userName,
    required this.contributionId,
    required this.groupName,
    required this.appliedById,
    required this.amount,
    required this.reason,
    required this.date,
    required this.status,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value is int) return value;
      if (value == null) return null;
      return int.tryParse(value.toString());
    }

    DateTime parseDate(dynamic value) {
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return Penalty(
      id: parseNullableInt(json['id']) ?? 0,
      userId: parseNullableInt(json['user']),
      userName: (json['user_name'] ?? '').toString().trim().isEmpty
          ? null
          : (json['user_name']).toString(),
      contributionId: parseNullableInt(json['contribution']),
      groupName: (json['group_name'] ?? '').toString().trim().isEmpty
          ? null
          : (json['group_name']).toString(),
      appliedById: parseNullableInt(json['applied_by']),
      amount: double.parse(json['amount'].toString()),
      reason: (json['reason'] ?? '').toString(),
      date: parseDate(json['created_at']),
      status: (json['status'] ?? 'UNPAID').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'user_name': userName,
      'contribution': contributionId,
      'group_name': groupName,
      'applied_by': appliedById,
      'amount': amount,
      'reason': reason,
      'created_at': date.toIso8601String(),
      'status': status,
    };
  }
}
