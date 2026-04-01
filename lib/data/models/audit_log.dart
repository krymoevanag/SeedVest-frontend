class AuditLogModel {
  final int id;
  final int? actorId;
  final String actorEmail;
  final int? targetUserId;
  final String targetEmail;
  final String action;
  final DateTime timestamp;
  final String notes;

  AuditLogModel({
    required this.id,
    this.actorId,
    required this.actorEmail,
    this.targetUserId,
    required this.targetEmail,
    required this.action,
    required this.timestamp,
    required this.notes,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      actorId: json['actor'],
      actorEmail: json['actor_email'] ?? 'SYSTEM',
      targetUserId: json['target_user'],
      targetEmail: json['target_email'] ?? 'DELETED',
      action: json['action'],
      timestamp: DateTime.parse(json['timestamp']),
      notes: json['notes'] ?? '',
    );
  }

  String get displayTitle {
    switch (action) {
      case 'MEMBERSHIP_CHANGE':
        return 'Membership Change';
      case 'ROLE_CHANGE':
        return 'User Role Updated';
      case 'APPROVAL':
        return 'Registration Approved';
      case 'DEACTIVATION':
        return 'Account Deactivated/Rejected';
      case 'LOGIN':
        return 'User Login';
      case 'PASSWORD_RESET':
        return 'Password Changed';
      case 'CONTRIBUTION_ADD':
        return 'Contribution Added';
      case 'PENALTY_ISSUE':
        return 'Penalty Issued';
      default:
        return action.replaceAll('_', ' ');
    }
  }
}
