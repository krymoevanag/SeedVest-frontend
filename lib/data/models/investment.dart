class Investment {
  final int id;
  final String name;
  final String description;
  final double amountInvested;
  final double expectedRoiPercentage;
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
    required this.amountInvested,
    required this.expectedRoiPercentage,
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
      name: json['name'],
      description: json['description'] ?? '',
      amountInvested: double.parse(json['amount_invested'].toString()),
      expectedRoiPercentage:
          double.parse(json['expected_roi_percentage']?.toString() ?? '0.0'),
      status: json['status'],
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
      'amount_invested': amountInvested,
      'expected_roi_percentage': expectedRoiPercentage,
      'status': status,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }
}
