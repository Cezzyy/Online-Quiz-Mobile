class Choice {
  final int choiceId;
  final int questionId;
  final String body;
  final bool isCorrect;

  const Choice({
    required this.choiceId,
    required this.questionId,
    required this.body,
    required this.isCorrect,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      choiceId: json['ChoiceId'] as int,
      questionId: json['QuestionId'] as int,
      body: json['Body'] as String,
      isCorrect: json['Is_Correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ChoiceId': choiceId,
      'QuestionId': questionId,
      'Body': body,
      'Is_Correct': isCorrect,
    };
  }

  Choice copyWith({
    int? choiceId,
    int? questionId,
    String? body,
    bool? isCorrect,
  }) {
    return Choice(
      choiceId: choiceId ?? this.choiceId,
      questionId: questionId ?? this.questionId,
      body: body ?? this.body,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Choice && other.choiceId == choiceId;
  }

  @override
  int get hashCode => choiceId.hashCode;

  @override
  String toString() {
    return 'Choice(choiceId: $choiceId, questionId: $questionId, body: $body, isCorrect: $isCorrect)';
  }
}