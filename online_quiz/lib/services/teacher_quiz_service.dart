import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/choice.dart';
import '../models/course.dart';
import 'quiz_notification_service.dart';

class TeacherQuizService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuizNotificationService _notificationService = QuizNotificationService();

  /// Create a new quiz
  Future<Quiz> createQuiz({
    required int courseId,
    required String title,
    required int createdBy,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool isPublished = false,
  }) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .insert({
            'CourseId': courseId,
            'Title': title,
            'Due_At': dueAt?.toIso8601String(),
            'Time_Limit_Minutes': timeLimitMinutes,
            'Is_Published': isPublished,
            'CreatedBy': createdBy,
            'CreatedAt': DateTime.now().toIso8601String(),
            'UpdatedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Quiz.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create quiz: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }

  /// Update an existing quiz
  Future<Quiz> updateQuiz({
    required int quizId,
    String? title,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool? isPublished,
  }) async {
    try {
      final updates = <String, dynamic>{
        'UpdatedAt': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['Title'] = title;
      if (dueAt != null) updates['Due_At'] = dueAt.toIso8601String();
      if (timeLimitMinutes != null) updates['Time_Limit_Minutes'] = timeLimitMinutes;
      if (isPublished != null) updates['Is_Published'] = isPublished;

      final response = await _supabase
          .from('Quiz')
          .update(updates)
          .eq('QuizId', quizId)
          .select()
          .single();

      return Quiz.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update quiz: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  /// Delete a quiz and all related data (questions, choices)
  Future<void> deleteQuiz(int quizId) async {
    try {
      // Get all questions for this quiz
      final questionsResponse = await _supabase
          .from('Question')
          .select('QuestionId')
          .eq('QuizId', quizId);

      final questionIds = questionsResponse
          .map((q) => q['QuestionId'] as int)
          .toList();

      // Delete choices for all questions (if any exist)
      if (questionIds.isNotEmpty) {
        await _supabase
            .from('Choice')
            .delete()
            .inFilter('QuestionId', questionIds);
      }

      // Delete all questions for this quiz
      await _supabase
          .from('Question')
          .delete()
          .eq('QuizId', quizId);

      // Delete the quiz itself
      await _supabase
          .from('Quiz')
          .delete()
          .eq('QuizId', quizId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete quiz: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }

  /// Toggle quiz published status
  Future<Quiz> togglePublishQuiz(int quizId, bool isPublished) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .update({
            'Is_Published': isPublished,
            'UpdatedAt': DateTime.now().toIso8601String(),
          })
          .eq('QuizId', quizId)
          .select()
          .single();

      return Quiz.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to toggle publish status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to toggle publish status: $e');
    }
  }

  // ==================== QUESTION CRUD OPERATIONS ====================

  /// Create a single question
  Future<Question> createQuestion({
    required int quizId,
    required String text,
    required QuestionType type,
    required int order,
    required double points,
    String? correctAnswer,
  }) async {
    try {
      final response = await _supabase
          .from('Question')
          .insert({
            'QuizId': quizId,
            'Body': text,
            'Type': type.value,
            'Sort_Order': order,
            'Points': points,
            'Correct_Answer': correctAnswer,
          })
          .select()
          .single();

      return Question.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create question: $e');
    }
  }

  /// Update an existing question
  Future<Question> updateQuestion({
    required int questionId,
    String? text,
    QuestionType? type,
    int? order,
    double? points,
    String? correctAnswer,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (text != null) updates['Text'] = text;
      if (type != null) updates['Type'] = type.toString().split('.').last;
      if (order != null) updates['Order'] = order;
      if (points != null) updates['Points'] = points;
      if (correctAnswer != null) updates['Correct_Answer'] = correctAnswer;

      final response = await _supabase
          .from('Question')
          .update(updates)
          .eq('QuestionId', questionId)
          .select()
          .single();

      return Question.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update question: $e');
    }
  }

  /// Delete a question and its choices
  Future<void> deleteQuestion(int questionId) async {
    try {
      // Delete all choices for this question first
      await _supabase
          .from('Choice')
          .delete()
          .eq('QuestionId', questionId);

      // Delete the question
      await _supabase
          .from('Question')
          .delete()
          .eq('QuestionId', questionId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete question: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  /// Bulk create questions (more efficient for quiz creation)
  Future<List<Question>> bulkCreateQuestions(List<Map<String, dynamic>> questions) async {
    try {
      final response = await _supabase
          .from('Question')
          .insert(questions)
          .select();

      return response.map((data) => Question.fromJson(data)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to create questions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create questions: $e');
    }
  }

  /// Create a single choice
  Future<Choice> createChoice({
    required int questionId,
    required String text,
    required bool isCorrect,
    required int order,
  }) async {
    try {
      final response = await _supabase
          .from('Choice')
          .insert({
            'QuestionId': questionId,
            'Body': text,
            'Is_Correct': isCorrect,
          })
          .select()
          .single();

      return Choice.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create choice: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create choice: $e');
    }
  }

  /// Update an existing choice
  Future<Choice> updateChoice({
    required int choiceId,
    String? text,
    bool? isCorrect,
    int? order,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (text != null) updates['Text'] = text;
      if (isCorrect != null) updates['IsCorrect'] = isCorrect;
      if (order != null) updates['Order'] = order;

      final response = await _supabase
          .from('Choice')
          .update(updates)
          .eq('ChoiceId', choiceId)
          .select()
          .single();

      return Choice.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update choice: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update choice: $e');
    }
  }

  /// Delete a choice
  Future<void> deleteChoice(int choiceId) async {
    try {
      await _supabase
          .from('Choice')
          .delete()
          .eq('ChoiceId', choiceId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete choice: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete choice: $e');
    }
  }

  /// Bulk create choices (more efficient for question creation)
  Future<List<Choice>> bulkCreateChoices(List<Map<String, dynamic>> choices) async {
    try {
      final response = await _supabase
          .from('Choice')
          .insert(choices)
          .select();

      return response.map((data) => Choice.fromJson(data)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to create choices: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create choices: $e');
    }
  }

  /// Create a complete quiz with questions and choices in one transaction
  Future<Quiz> createCompleteQuiz({
    required int courseId,
    required String title,
    required int createdBy,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool isPublished = false,
    required List<Map<String, dynamic>> questionsWithChoices,
  }) async {
    try {
      // 1. Create the quiz
      final quiz = await createQuiz(
        courseId: courseId,
        title: title,
        createdBy: createdBy,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
      );

      // 2. Create questions with the quiz ID
      for (int i = 0; i < questionsWithChoices.length; i++) {
        final questionData = questionsWithChoices[i];
        
        final question = await createQuestion(
          quizId: quiz.quizId,
          text: questionData['text'],
          type: QuestionType.fromString(questionData['type']),
          order: i + 1,
          points: questionData['points'],
          correctAnswer: questionData['correctAnswer'],
        );

        // 3. Create choices for this question
        final choices = questionData['choices'] as List<Map<String, dynamic>>;
        for (int j = 0; j < choices.length; j++) {
          await createChoice(
            questionId: question.questionId,
            text: choices[j]['text'],
            isCorrect: choices[j]['isCorrect'],
            order: j + 1,
          );
        }
      }

      return quiz;
    } catch (e) {
      // If anything fails, we should ideally rollback, but Supabase doesn't support transactions in the client
      // The quiz might be created without questions - handle this in the UI
      throw Exception('Failed to create complete quiz: $e');
    }
  }

  /// Update a complete quiz with questions and choices
  Future<Quiz> updateCompleteQuiz({
    required int quizId,
    String? title,
    DateTime? dueAt,
    int? timeLimitMinutes,
    bool? isPublished,
    List<Map<String, dynamic>>? questionsWithChoices,
  }) async {
    try {
      // 1. Update the quiz
      final quiz = await updateQuiz(
        quizId: quizId,
        title: title,
        dueAt: dueAt,
        timeLimitMinutes: timeLimitMinutes,
        isPublished: isPublished,
      );

      // 2. If questions are provided, replace all questions
      if (questionsWithChoices != null) {
        // Get existing questions
        final existingQuestions = await _supabase
            .from('Question')
            .select('QuestionId')
            .eq('QuizId', quizId);

        final existingQuestionIds = existingQuestions
            .map((q) => q['QuestionId'] as int)
            .toList();

        // Delete existing choices and questions
        if (existingQuestionIds.isNotEmpty) {
          await _supabase
              .from('Choice')
              .delete()
              .inFilter('QuestionId', existingQuestionIds);
          
          await _supabase
              .from('Question')
              .delete()
              .eq('QuizId', quizId);
        }

        // Create new questions and choices
        for (int i = 0; i < questionsWithChoices.length; i++) {
          final questionData = questionsWithChoices[i];
          
          final question = await createQuestion(
            quizId: quizId,
            text: questionData['text'],
            type: QuestionType.fromString(questionData['type']),
            order: i + 1,
            points: questionData['points'],
            correctAnswer: questionData['correctAnswer'],
          );

          final choices = questionData['choices'] as List<Map<String, dynamic>>;
          for (int j = 0; j < choices.length; j++) {
            await createChoice(
              questionId: question.questionId,
              text: choices[j]['text'],
              isCorrect: choices[j]['isCorrect'],
              order: j + 1,
            );
          }
        }
      }

      // 3. If quiz is being published, send notifications to enrolled students
      if (isPublished == true && quiz.isPublished) {
        try {
          // Get course information
          final courseResponse = await _supabase
              .from('Course')
              .select('*')
              .eq('CourseId', quiz.courseId)
              .single();

          final course = Course.fromJson(courseResponse);

          // Send new quiz notification
          await _notificationService.notifyNewQuiz(
            quiz: quiz,
            course: course,
          );

          if (kDebugMode) {
            debugPrint('Sent new quiz notification for: ${quiz.title}');
          }
        } catch (e) {
          // Don't fail the update if notification fails
          if (kDebugMode) {
            debugPrint('Failed to send quiz notification: $e');
          }
        }
      }

      return quiz;
    } catch (e) {
      throw Exception('Failed to update complete quiz: $e');
    }
  }

  /// Get question count for a quiz
  Future<int> getQuestionCount(int quizId) async {
    try {
      final response = await _supabase
          .from('Question')
          .select('QuestionId')
          .eq('QuizId', quizId);

      return response.length;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get question count: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get question count: $e');
    }
  }

  /// Get total points for a quiz
  Future<double> getTotalPoints(int quizId) async {
    try {
      final response = await _supabase
          .from('Question')
          .select('Points')
          .eq('QuizId', quizId);

      if (response.isEmpty) return 0.0;

      return response.fold<double>(
        0.0,
        (sum, question) => sum + (question['Points'] as num).toDouble(),
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to get total points: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get total points: $e');
    }
  }

  /// Validate quiz before publishing
  Future<Map<String, dynamic>> validateQuiz(int quizId) async {
    try {
      final questions = await _supabase
          .from('Question')
          .select('QuestionId, Type, Correct_Answer')
          .eq('QuizId', quizId);

      if (questions.isEmpty) {
        return {
          'valid': false,
          'message': 'Quiz must have at least one question',
        };
      }

      // Check each question has choices (except text type)
      for (final question in questions) {
        final questionId = question['QuestionId'] as int;
        final type = question['Type'] as String;
        final correctAnswer = question['Correct_Answer'] as String?;

        if (type == 'Text') {
          // Text questions must have a correct answer
          if (correctAnswer == null || correctAnswer.trim().isEmpty) {
            return {
              'valid': false,
              'message': 'All text questions must have a correct answer specified',
            };
          }
        } else {
          // Multiple choice questions must have choices and correct answers
          final choices = await _supabase
              .from('Choice')
              .select('ChoiceId, IsCorrect')
              .eq('QuestionId', questionId);

          if (choices.isEmpty) {
            return {
              'valid': false,
              'message': 'All multiple choice questions must have at least one choice',
            };
          }

          // Check for correct answer
          final hasCorrectAnswer = choices.any((c) => c['IsCorrect'] == true);
          if (!hasCorrectAnswer) {
            return {
              'valid': false,
              'message': 'All multiple choice questions must have at least one correct answer',
            };
          }
        }
      }

      return {
        'valid': true,
        'message': 'Quiz is ready to be published',
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Failed to validate quiz: $e',
      };
    }
  }
}
