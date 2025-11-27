enum QuestionType {
  single('Single'),
  multiple('Multiple'),
  text('Text');

  const QuestionType(this.value);
  final String value;

  static QuestionType fromString(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QuestionType.single,
    );
  }
}

class Question {
  final int questionId;
  final int quizId;
  final QuestionType type;
  final String body;
  final double points;
  final int sortOrder;
  final String? correctAnswer; // For text-type questions

  const Question({
    required this.questionId,
    required this.quizId,
    required this.type,
    required this.body,
    required this.points,
    required this.sortOrder,
    this.correctAnswer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      questionId: json['QuestionId'] as int,
      quizId: json['QuizId'] as int,
      type: QuestionType.fromString(json['Type'] as String),
      body: json['Body'] as String,
      points: (json['Points'] as num).toDouble(),
      sortOrder: json['Sort_Order'] as int,
      correctAnswer: json['Correct_Answer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'QuestionId': questionId,
      'QuizId': quizId,
      'Type': type.value,
      'Body': body,
      'Points': points,
      'Sort_Order': sortOrder,
      'Correct_Answer': correctAnswer,
    };
  }

  Question copyWith({
    int? questionId,
    int? quizId,
    QuestionType? type,
    String? body,
    double? points,
    int? sortOrder,
    String? correctAnswer,
  }) {
    return Question(
      questionId: questionId ?? this.questionId,
      quizId: quizId ?? this.quizId,
      type: type ?? this.type,
      body: body ?? this.body,
      points: points ?? this.points,
      sortOrder: sortOrder ?? this.sortOrder,
      correctAnswer: correctAnswer ?? this.correctAnswer,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.questionId == questionId;
  }

  @override
  int get hashCode => questionId.hashCode;

  @override
  String toString() {
    return 'Question(questionId: $questionId, quizId: $quizId, type: $type, body: $body, points: $points, sortOrder: $sortOrder)';
  }

  // Helper methods
  bool get isMultipleChoice => type == QuestionType.single || type == QuestionType.multiple;
  bool get isTextQuestion => type == QuestionType.text;
  bool get allowsMultipleAnswers => type == QuestionType.multiple;
}