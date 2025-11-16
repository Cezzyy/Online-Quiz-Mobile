class Quiz {
  final int quizId;
  final int courseId;
  final String title;
  final DateTime? dueAt;
  final int? timeLimitMinutes;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int createdBy;

  const Quiz({
    required this.quizId,
    required this.courseId,
    required this.title,
    this.dueAt,
    this.timeLimitMinutes,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      quizId: json['QuizId'] as int,
      courseId: json['CourseId'] as int,
      title: json['Title'] as String,
      dueAt: json['Due_At'] != null ? DateTime.parse(json['Due_At'] as String) : null,
      timeLimitMinutes: json['Time_Limit_Minutes'] as int?,
      isPublished: json['Is_Published'] as bool,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      createdBy: json['CreatedBy'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QuizId': quizId,
      'CourseId': courseId,
      'Title': title,
      'Due_At': dueAt?.toIso8601String(),
      'Time_Limit_Minutes': timeLimitMinutes,
      'Is_Published': isPublished,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'CreatedBy': createdBy,
    };
  }

  Quiz copyWith({
    int? quizId,
    int? courseId,
    String? title,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
  }) {
    return Quiz(
      quizId: quizId ?? this.quizId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      dueAt: dueAt ?? this.dueAt,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quiz && other.quizId == quizId;
  }

  @override
  int get hashCode => quizId.hashCode;

  @override
  String toString() {
    return 'Quiz(quizId: $quizId, courseId: $courseId, title: $title, dueAt: $dueAt, timeLimitMinutes: $timeLimitMinutes, isPublished: $isPublished)';
  }

  // Helper methods
  bool get isOverdue => dueAt != null && DateTime.now().isAfter(dueAt!);
  bool get hasDueDate => dueAt != null;
  bool get hasTimeLimit => timeLimitMinutes != null;
  
  Duration? get timeLimit => timeLimitMinutes != null ? Duration(minutes: timeLimitMinutes!) : null;
  
  int get daysUntilDue {
    if (dueAt == null) return 0;
    return dueAt!.difference(DateTime.now()).inDays;
  }
}