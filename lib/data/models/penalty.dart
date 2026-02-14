class Penalty {
  final int id;
  final int userId;
  final double amount;
  final String reason;
  final DateTime date;
  final String status;

  Penalty({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.date,
    required this.status,
  });

  factory Penalty.fromJson(Map<String, dynamic> json) {
    return Penalty(
      id: json['id'],
      userId: json['user'],
      amount: double.parse(json['amount'].toString()),
      reason: json['reason'],
      date: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'amount': amount,
      'reason': reason,
      'created_at': date.toIso8601String(),
      'status': status,
    };
  }
}
