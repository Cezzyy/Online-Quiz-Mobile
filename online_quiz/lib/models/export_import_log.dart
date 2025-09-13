enum LogType {
  export('Export'),
  import('Import');

  const LogType(this.value);
  final String value;

  static LogType fromString(String value) {
    return LogType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LogType.export,
    );
  }
}

enum LogStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  failed('Failed');

  const LogStatus(this.value);
  final String value;

  static LogStatus fromString(String value) {
    return LogStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LogStatus.pending,
    );
  }
}

class ExportImportLog {
  final int logId;
  final int userId;
  final LogType type;
  final String fileName;
  final LogStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const ExportImportLog({
    required this.logId,
    required this.userId,
    required this.type,
    required this.fileName,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  factory ExportImportLog.fromJson(Map<String, dynamic> json) {
    return ExportImportLog(
      logId: json['LogId'] as int,
      userId: json['UserId'] as int,
      type: LogType.fromString(json['Type'] as String),
      fileName: json['FileName'] as String,
      status: LogStatus.fromString(json['Status'] as String),
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      completedAt: json['CompletedAt'] != null ? DateTime.parse(json['CompletedAt'] as String) : null,
      errorMessage: json['ErrorMessage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'LogId': logId,
      'UserId': userId,
      'Type': type.value,
      'FileName': fileName,
      'Status': status.value,
      'CreatedAt': createdAt.toIso8601String(),
      'CompletedAt': completedAt?.toIso8601String(),
      'ErrorMessage': errorMessage,
    };
  }

  ExportImportLog copyWith({
    int? logId,
    int? userId,
    LogType? type,
    String? fileName,
    LogStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return ExportImportLog(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportImportLog && other.logId == logId;
  }

  @override
  int get hashCode => logId.hashCode;

  @override
  String toString() {
    return 'ExportImportLog(logId: $logId, userId: $userId, type: $type, fileName: $fileName, status: $status, createdAt: $createdAt, completedAt: $completedAt, errorMessage: $errorMessage)';
  }

  // Helper methods
  bool get isCompleted => status == LogStatus.completed;
  bool get isFailed => status == LogStatus.failed;
  bool get isInProgress => status == LogStatus.inProgress;
  bool get isPending => status == LogStatus.pending;
  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
  
  Duration? get processingTime {
    if (completedAt != null) {
      return completedAt!.difference(createdAt);
    }
    return null;
  }
}