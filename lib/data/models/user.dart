class User {
  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool isApproved;
  final String applicationStatus;
  final bool isSuperuser;
  final String? phoneNumber;
  final String? membershipNumber;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.isApproved = false,
    this.applicationStatus = 'PENDING',
    this.isSuperuser = false,
    this.phoneNumber,
    this.membershipNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      role: json['role'] ?? 'MEMBER',
      isApproved: json['is_approved'] ?? false,
      applicationStatus: json['application_status'] ??
          'APPROVED', // Default to APPROVED for existing users if missing
      isSuperuser: json['is_superuser'] ?? false,
      phoneNumber: json['phone_number'],
      membershipNumber: json['membership_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'is_approved': isApproved,
      'application_status': applicationStatus,
      'is_superuser': isSuperuser,
      'phone_number': phoneNumber,
      'membership_number': membershipNumber,
    };
  }
}
