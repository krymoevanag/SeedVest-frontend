class AuditLogModel {
  final int id;
  final int? actorId;
  final String actorEmail;
  final String actorName;
  final String actorRole;
  final int? targetUserId;
  final String targetEmail;
  final String targetName;
  final String action;
  final DateTime timestamp;
  final String notes;

  AuditLogModel({
    required this.id,
    this.actorId,
    required this.actorEmail,
    required this.actorName,
    required this.actorRole,
    this.targetUserId,
    required this.targetEmail,
    required this.targetName,
    required this.action,
    required this.timestamp,
    required this.notes,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'],
      actorId: json['actor'],
      actorEmail: json['actor_email'] ?? 'SYSTEM',
      actorName: json['actor_name'] ?? json['actor_email'] ?? 'SYSTEM',
      actorRole: json['actor_role'] ?? '',
      targetUserId: json['target_user'],
      targetEmail: json['target_email'] ?? 'Deleted User',
      targetName: json['target_name'] ?? json['target_email'] ?? 'Deleted User',
      action: json['action'] ?? '',
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
        return 'Approval Action';
      case 'ACTIVATION':
        return 'Account Activated';
      case 'DEACTIVATION':
        return 'Account Deactivated';
      case 'LOGIN':
        return 'User Login';
      case 'PASSWORD_RESET':
        return 'Password Changed';
      case 'CONTRIBUTION_ADD':
        return 'Contribution Added';
      case 'PENALTY_ISSUE':
        return 'Penalty Issued';
      case 'FINANCE_CHANGE':
        return 'Finance Record Updated';
      case 'FINANCE_ARCHIVE':
        return 'Finance Record Archived';
      default:
        return action.replaceAll('_', ' ');
    }
  }

  /// Icon to visually represent the action type
  String get actionIcon {
    switch (action) {
      case 'CONTRIBUTION_ADD':
        return 'savings';
      case 'PENALTY_ISSUE':
        return 'gavel';
      case 'LOAN_ACTION':
        return 'account_balance';
      case 'APPROVAL':
        return 'check_circle';
      case 'DEACTIVATION':
        return 'cancel';
      case 'ACTIVATION':
        return 'verified';
      case 'MEMBERSHIP_CHANGE':
        return 'group';
      case 'FINANCE_CHANGE':
      case 'FINANCE_ARCHIVE':
        return 'edit_note';
      case 'LOGIN':
        return 'login';
      default:
        return 'history';
    }
  }
}
