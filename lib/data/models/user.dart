class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final bool isApproved;
  final String? phoneNumber;
  final String? membershipNumber;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.isApproved = false,
    this.phoneNumber,
    this.membershipNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'MEMBER',
      isApproved: json['is_approved'] ?? false,
      phoneNumber: json['phone_number'],
      membershipNumber: json['membership_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_approved': isApproved,
      'phone_number': phoneNumber,
      'membership_number': membershipNumber,
    };
  }
}
