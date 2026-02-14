class Contribution {
  final int id;
  final int userId;
  final double amount;
  final DateTime date;
  final String status;
  final String? transactionId;

  Contribution({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.status,
    this.transactionId,
  });

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'],
      userId: json['user'],
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      transactionId: json['transaction_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'amount': amount,
      'created_at': date.toIso8601String(),
      'status': status,
      'transaction_id': transactionId,
    };
  }
}
