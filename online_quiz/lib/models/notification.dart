enum NotificationType {
  quiz('Quiz'),
  course('Course'),
  system('System'),
  reminder('Reminder');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

class Notification {
  final int notificationId;
  final int userId;
  final NotificationType type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      notificationId: json['NotificationId'] as int,
      userId: json['UserId'] as int,
      type: NotificationType.fromString(json['Type'] as String),
      title: json['Title'] as String,
      message: json['Message'] as String,
      isRead: json['Is_Read'] as bool,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'NotificationId': notificationId,
      'UserId': userId,
      'Type': type.value,
      'Title': title,
      'Message': message,
      'Is_Read': isRead,
      'CreatedAt': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    int? notificationId,
    int? userId,
    NotificationType? type,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification && other.notificationId == notificationId;
  }

  @override
  int get hashCode => notificationId.hashCode;

  @override
  String toString() {
    return 'Notification(notificationId: $notificationId, userId: $userId, type: $type, title: $title, message: $message, isRead: $isRead, createdAt: $createdAt)';
  }

  // Helper methods
  bool get isUnread => !isRead;
  
  Notification markAsRead() => copyWith(isRead: true);
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}