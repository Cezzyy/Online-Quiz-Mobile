import 'dart:convert';

/// Enum for activity log actions
enum ActivityAction {
  create,
  update,
  delete,
  login,
  logout,
  publish,
  unpublish,
  enroll,
  unenroll,
  submit,
  grade,
  export,
  import,
  archive,
  restore,
  approve,
  reject;

  String get value {
    switch (this) {
      case ActivityAction.create:
        return 'CREATE';
      case ActivityAction.update:
        return 'UPDATE';
      case ActivityAction.delete:
        return 'DELETE';
      case ActivityAction.login:
        return 'LOGIN';
      case ActivityAction.logout:
        return 'LOGOUT';
      case ActivityAction.publish:
        return 'PUBLISH';
      case ActivityAction.unpublish:
        return 'UNPUBLISH';
      case ActivityAction.enroll:
        return 'ENROLL';
      case ActivityAction.unenroll:
        return 'UNENROLL';
      case ActivityAction.submit:
        return 'SUBMIT';
      case ActivityAction.grade:
        return 'GRADE';
      case ActivityAction.export:
        return 'EXPORT';
      case ActivityAction.import:
        return 'IMPORT';
      case ActivityAction.archive:
        return 'ARCHIVE';
      case ActivityAction.restore:
        return 'RESTORE';
      case ActivityAction.approve:
        return 'APPROVE';
      case ActivityAction.reject:
        return 'REJECT';
    }
  }

  static ActivityAction fromString(String value) {
    return ActivityAction.values.firstWhere(
      (action) => action.value == value,
      orElse: () => ActivityAction.create,
    );
  }
}

/// Enum for entity types
enum EntityType {
  user,
  teacher,
  student,
  course,
  enrollment,
  quiz,
  question,
  choice,
  attempt,
  attemptAnswer,
  notification,
  system,
  auth;

  String get value {
    switch (this) {
      case EntityType.user:
        return 'User';
      case EntityType.teacher:
        return 'Teacher';
      case EntityType.student:
        return 'Student';
      case EntityType.course:
        return 'Course';
      case EntityType.enrollment:
        return 'Enrollment';
      case EntityType.quiz:
        return 'Quiz';
      case EntityType.question:
        return 'Question';
      case EntityType.choice:
        return 'Choice';
      case EntityType.attempt:
        return 'Attempt';
      case EntityType.attemptAnswer:
        return 'AttemptAnswer';
      case EntityType.notification:
        return 'Notification';
      case EntityType.system:
        return 'System';
      case EntityType.auth:
        return 'Auth';
    }
  }

  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (entity) => entity.value == value,
      orElse: () => EntityType.system,
    );
  }
}

/// Activity Log model for audit trail
class ActivityLog {
  final int activityLogId;
  final int userId;
  final ActivityAction action;
  final EntityType entity;
  final int? entityId;
  final String? description;
  final Map<String, dynamic>? oldValues;
  final Map<String, dynamic>? newValues;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  // For joined queries
  final String? userName;
  final String? userEmail;

  ActivityLog({
    required this.activityLogId,
    required this.userId,
    required this.action,
    required this.entity,
    this.entityId,
    this.description,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    this.userName,
    this.userEmail,
  });

  /// Create ActivityLog from Supabase JSON
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      activityLogId: json['ActivityLogId'] as int,
      userId: json['UserId'] as int,
      action: ActivityAction.fromString(json['Action'] as String),
      entity: EntityType.fromString(json['Entity'] as String),
      entityId: json['EntityId'] as int?,
      description: json['Description'] as String?,
      oldValues: json['OldValues'] != null
          ? jsonDecode(json['OldValues'] as String)
          : null,
      newValues: json['NewValues'] != null
          ? jsonDecode(json['NewValues'] as String)
          : null,
      ipAddress: json['IpAddress'] as String?,
      userAgent: json['UserAgent'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      userName: json['userName'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }

  /// Convert ActivityLog to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Action': action.value,
      'Entity': entity.value,
      'EntityId': entityId,
      'Description': description,
      'OldValues': oldValues != null ? jsonEncode(oldValues) : null,
      'NewValues': newValues != null ? jsonEncode(newValues) : null,
      'IpAddress': ipAddress,
      'UserAgent': userAgent,
    };
  }

  /// Copy with method for immutability
  ActivityLog copyWith({
    int? activityLogId,
    int? userId,
    ActivityAction? action,
    EntityType? entity,
    int? entityId,
    String? description,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    String? userName,
    String? userEmail,
  }) {
    return ActivityLog(
      activityLogId: activityLogId ?? this.activityLogId,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      description: description ?? this.description,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }

  /// Get a human-readable action text
  String get actionText {
    switch (action) {
      case ActivityAction.create:
        return 'Created';
      case ActivityAction.update:
        return 'Updated';
      case ActivityAction.delete:
        return 'Deleted';
      case ActivityAction.login:
        return 'Logged In';
      case ActivityAction.logout:
        return 'Logged Out';
      case ActivityAction.publish:
        return 'Published';
      case ActivityAction.unpublish:
        return 'Unpublished';
      case ActivityAction.enroll:
        return 'Enrolled';
      case ActivityAction.unenroll:
        return 'Unenrolled';
      case ActivityAction.submit:
        return 'Submitted';
      case ActivityAction.grade:
        return 'Graded';
      case ActivityAction.export:
        return 'Exported';
      case ActivityAction.import:
        return 'Imported';
      case ActivityAction.archive:
        return 'Archived';
      case ActivityAction.restore:
        return 'Restored';
      case ActivityAction.approve:
        return 'Approved';
      case ActivityAction.reject:
        return 'Rejected';
    }
  }

  /// Get a human-readable entity text
  String get entityText {
    switch (entity) {
      case EntityType.user:
        return 'User';
      case EntityType.teacher:
        return 'Teacher';
      case EntityType.student:
        return 'Student';
      case EntityType.course:
        return 'Course';
      case EntityType.enrollment:
        return 'Enrollment';
      case EntityType.quiz:
        return 'Quiz';
      case EntityType.question:
        return 'Question';
      case EntityType.choice:
        return 'Choice';
      case EntityType.attempt:
        return 'Quiz Attempt';
      case EntityType.attemptAnswer:
        return 'Answer';
      case EntityType.notification:
        return 'Notification';
      case EntityType.system:
        return 'System';
      case EntityType.auth:
        return 'Authentication';
    }
  }

  @override
  String toString() {
    return 'ActivityLog(id: $activityLogId, user: $userId, action: ${action.value}, entity: ${entity.value})';
  }
}

/// Activity statistics model
class ActivityStatistics {
  final int totalActions;
  final int uniqueUsers;
  final Map<String, int> actionsByType;
  final Map<String, int> entitiesAffected;
  final List<RecentActivity> recentActivity;

  ActivityStatistics({
    required this.totalActions,
    required this.uniqueUsers,
    required this.actionsByType,
    required this.entitiesAffected,
    required this.recentActivity,
  });

  factory ActivityStatistics.fromJson(Map<String, dynamic> json) {
    return ActivityStatistics(
      totalActions: json['total_actions'] as int? ?? 0,
      uniqueUsers: json['unique_users'] as int? ?? 0,
      actionsByType: json['actions_by_type'] != null
          ? Map<String, int>.from(json['actions_by_type'] as Map)
          : {},
      entitiesAffected: json['entities_affected'] != null
          ? Map<String, int>.from(json['entities_affected'] as Map)
          : {},
      recentActivity: json['recent_activity'] != null
          ? (json['recent_activity'] as List)
              .map((item) => RecentActivity.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

/// Recent activity summary
class RecentActivity {
  final int activityLogId;
  final String action;
  final String entity;
  final String? description;
  final DateTime createdAt;
  final String userName;

  RecentActivity({
    required this.activityLogId,
    required this.action,
    required this.entity,
    this.description,
    required this.createdAt,
    required this.userName,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      activityLogId: json['ActivityLogId'] as int,
      action: json['Action'] as String,
      entity: json['Entity'] as String,
      description: json['Description'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      userName: json['user_name'] as String,
    );
  }
}
