class Investment {
  final int id;
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String status;
  final double expectedRoi;

  Investment({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    required this.status,
    required this.expectedRoi,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      amount: double.parse(json['amount'].toString()),
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      expectedRoi: double.parse(json['expected_roi']?.toString() ?? '0.0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'created_at': date.toIso8601String(),
      'status': status,
      'expected_roi': expectedRoi,
    };
  }
}
