class AttemptAnswer {
  final int attemptAnswerId;
  final int attemptId;
  final int questionId;
  final int? choiceId;
  final String? freeText;
  final bool? isCorrect;
  final double? pointsAwarded;
  final String? feedback;

  const AttemptAnswer({
    required this.attemptAnswerId,
    required this.attemptId,
    required this.questionId,
    this.choiceId,
    this.freeText,
    this.isCorrect,
    this.pointsAwarded,
    this.feedback,
  });

  factory AttemptAnswer.fromJson(Map<String, dynamic> json) {
    return AttemptAnswer(
      attemptAnswerId: json['AttemptAnswerId'] as int,
      attemptId: json['AttemptId'] as int,
      questionId: json['QuestionId'] as int,
      choiceId: json['ChoiceId'] as int?,
      freeText: json['Free_Text'] as String?,
      isCorrect: json['Is_Correct'] as bool?,
      pointsAwarded: json['Points_Awarded'] != null ? (json['Points_Awarded'] as num).toDouble() : null,
      feedback: json['Feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AttemptAnswerId': attemptAnswerId,
      'AttemptId': attemptId,
      'QuestionId': questionId,
      'ChoiceId': choiceId,
      'Free_Text': freeText,
      'Is_Correct': isCorrect,
      'Points_Awarded': pointsAwarded,
      'Feedback': feedback,
    };
  }

  AttemptAnswer copyWith({
    int? attemptAnswerId,
    int? attemptId,
    int? questionId,
    int? choiceId,
    String? freeText,
    bool? isCorrect,
    double? pointsAwarded,
    String? feedback,
  }) {
    return AttemptAnswer(
      attemptAnswerId: attemptAnswerId ?? this.attemptAnswerId,
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      choiceId: choiceId ?? this.choiceId,
      freeText: freeText ?? this.freeText,
      isCorrect: isCorrect ?? this.isCorrect,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
      feedback: feedback ?? this.feedback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttemptAnswer && other.attemptAnswerId == attemptAnswerId;
  }

  @override
  int get hashCode => attemptAnswerId.hashCode;

  @override
  String toString() {
    return 'AttemptAnswer(attemptAnswerId: $attemptAnswerId, attemptId: $attemptId, questionId: $questionId, choiceId: $choiceId, freeText: $freeText, isCorrect: $isCorrect, pointsAwarded: $pointsAwarded, feedback: $feedback)';
  }

  // Helper methods
  bool get hasChoiceAnswer => choiceId != null;
  bool get hasTextAnswer => freeText != null && freeText!.isNotEmpty;
  bool get hasAnswer => hasChoiceAnswer || hasTextAnswer;
  bool get isAnswered => hasAnswer;
  bool get needsGrading => hasTextAnswer && isCorrect == null;
  bool get isGraded => hasTextAnswer && isCorrect != null;
}