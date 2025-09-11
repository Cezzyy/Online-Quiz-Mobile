class Attempt {
  final int attemptId;
  final int quizId;
  final int userId;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double score;
  final int? timeSpentSeconds;

  const Attempt({
    required this.attemptId,
    required this.quizId,
    required this.userId,
    required this.startedAt,
    this.submittedAt,
    required this.score,
    this.timeSpentSeconds,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      attemptId: json['AttemptId'] as int,
      quizId: json['QuizId'] as int,
      userId: json['UserId'] as int,
      startedAt: DateTime.parse(json['StartedAt'] as String),
      submittedAt: json['SubmittedAt'] != null ? DateTime.parse(json['SubmittedAt'] as String) : null,
      score: (json['Score'] as num).toDouble(),
      timeSpentSeconds: json['Time_Spent_Seconds'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AttemptId': attemptId,
      'QuizId': quizId,
      'UserId': userId,
      'StartedAt': startedAt.toIso8601String(),
      'SubmittedAt': submittedAt?.toIso8601String(),
      'Score': score,
      'Time_Spent_Seconds': timeSpentSeconds,
    };
  }

  Attempt copyWith({
    int? attemptId,
    int? quizId,
    int? userId,
    DateTime? startedAt,
    DateTime? submittedAt,
    double? score,
    int? timeSpentSeconds,
  }) {
    return Attempt(
      attemptId: attemptId ?? this.attemptId,
      quizId: quizId ?? this.quizId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      score: score ?? this.score,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attempt && other.attemptId == attemptId;
  }

  @override
  int get hashCode => attemptId.hashCode;

  @override
  String toString() {
    return 'Attempt(attemptId: $attemptId, quizId: $quizId, userId: $userId, startedAt: $startedAt, submittedAt: $submittedAt, score: $score, timeSpentSeconds: $timeSpentSeconds)';
  }

  // Helper methods
  bool get isCompleted => submittedAt != null;
  bool get isInProgress => submittedAt == null;
  
  Duration? get timeSpent => timeSpentSeconds != null ? Duration(seconds: timeSpentSeconds!) : null;
  
  int get timeSpentMinutes => timeSpentSeconds != null ? (timeSpentSeconds! / 60).round() : 0;
  
  Duration get elapsedTime => DateTime.now().difference(startedAt);
}