import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz.dart';
import '../models/question.dart';
import '../models/choice.dart';
import '../models/attempt.dart';
import '../models/attempt_answer.dart';
import 'activity_log_service.dart';

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ActivityLogService _activityLog = ActivityLogService();

  // Get all published quizzes for a specific course
  Future<List<Quiz>> getQuizzesByCourse(int courseId) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .select('*')
          .eq('CourseId', courseId)
          .eq('Is_Published', true)
          .order('CreatedAt', ascending: false);

      final List<Quiz> quizzes = [];
      for (final quizData in response) {
        quizzes.add(Quiz.fromJson(quizData));
      }

      return quizzes;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quizzes: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quizzes: $e');
    }
  }

  // Get all quizzes available to a student (from enrolled courses)
  Future<List<Quiz>> getAvailableQuizzes(int userId) async {
    try {
      debugPrint('getAvailableQuizzes: Fetching quizzes for userId: $userId');
      
      // First, get all courses the user is enrolled in
      final enrollments = await _supabase
          .from('Enrollment')
          .select('CourseId')
          .eq('UserId', userId);

      debugPrint('getAvailableQuizzes: Found ${enrollments.length} enrollments');
      
      final courseIds = enrollments.map((e) => e['CourseId'] as int).toList();

      if (courseIds.isEmpty) {
        debugPrint('getAvailableQuizzes: No enrollments found for user');
        return [];
      }

      debugPrint('getAvailableQuizzes: Enrolled in courses: $courseIds');

      // Get all published quizzes from enrolled courses
      final response = await _supabase
          .from('Quiz')
          .select('*')
          .inFilter('CourseId', courseIds)
          .eq('Is_Published', true)
          .order('Due_At', ascending: true);

      debugPrint('getAvailableQuizzes: Found ${response.length} published quizzes');

      final List<Quiz> quizzes = [];
      for (final quizData in response) {
        quizzes.add(Quiz.fromJson(quizData));
      }

      return quizzes;
    } on PostgrestException catch (e) {
      debugPrint('getAvailableQuizzes: PostgrestException - ${e.message}');
      throw Exception('Failed to fetch available quizzes: ${e.message}');
    } catch (e) {
      debugPrint('getAvailableQuizzes: Exception - $e');
      throw Exception('Failed to fetch available quizzes: $e');
    }
  }

  // Get quiz details by ID
  Future<Quiz?> getQuizById(int quizId) async {
    try {
      final response = await _supabase
          .from('Quiz')
          .select('*')
          .eq('QuizId', quizId)
          .maybeSingle();

      if (response == null) return null;

      return Quiz.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz: $e');
    }
  }

  // Get all questions for a quiz
  Future<List<Question>> getQuizQuestions(int quizId) async {
    try {
      final response = await _supabase
          .from('Question')
          .select('*')
          .eq('QuizId', quizId)
          .order('Sort_Order', ascending: true);

      final List<Question> questions = [];
      for (final questionData in response) {
        questions.add(Question.fromJson(questionData));
      }

      return questions;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch questions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch questions: $e');
    }
  }

  // Get choices for a specific question
  Future<List<Choice>> getQuestionChoices(int questionId) async {
    try {
      final response = await _supabase
          .from('Choice')
          .select('*')
          .eq('QuestionId', questionId);

      final List<Choice> choices = [];
      for (final choiceData in response) {
        choices.add(Choice.fromJson(choiceData));
      }

      return choices;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch choices: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch choices: $e');
    }
  }

  // Get choices for multiple questions (bulk fetch)
  Future<Map<int, List<Choice>>> getChoicesForQuestions(List<int> questionIds) async {
    try {
      if (questionIds.isEmpty) return {};

      final response = await _supabase
          .from('Choice')
          .select('*')
          .inFilter('QuestionId', questionIds);

      final Map<int, List<Choice>> choicesByQuestion = {};
      for (final choiceData in response) {
        final choice = Choice.fromJson(choiceData);
        if (!choicesByQuestion.containsKey(choice.questionId)) {
          choicesByQuestion[choice.questionId] = [];
        }
        choicesByQuestion[choice.questionId]!.add(choice);
      }

      return choicesByQuestion;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch choices: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch choices: $e');
    }
  }

  // Get user's attempts for a specific quiz
  Future<List<Attempt>> getUserQuizAttempts(int userId, int quizId) async {
    try {
      final response = await _supabase
          .from('Attempt')
          .select('*')
          .eq('UserId', userId)
          .eq('QuizId', quizId)
          .order('StartedAt', ascending: false);

      final List<Attempt> attempts = [];
      for (final attemptData in response) {
        attempts.add(Attempt.fromJson(attemptData));
      }

      return attempts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attempts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attempts: $e');
    }
  }

  // Get all user's attempts (across all quizzes)
  Future<List<Attempt>> getUserAttempts(int userId) async {
    try {
      final response = await _supabase
          .from('Attempt')
          .select('''
            *,
            Quiz:QuizId (
              QuizId,
              Title,
              CourseId,
              Course:CourseId (
                CourseId,
                Name,
                Code
              )
            )
          ''')
          .eq('UserId', userId)
          .order('StartedAt', ascending: false);

      final List<Attempt> attempts = [];
      for (final attemptData in response) {
        attempts.add(Attempt.fromJson(attemptData));
      }

      return attempts;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch user attempts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch user attempts: $e');
    }
  }

  // Start a new quiz attempt
  Future<Attempt> startAttempt(int userId, int quizId) async {
    try {
      // Check if there's already an in-progress attempt
      final existingAttempts = await getUserQuizAttempts(userId, quizId);
      final inProgressAttempt = existingAttempts.where((a) => a.submittedAt == null).firstOrNull;

      if (inProgressAttempt != null) {
        return inProgressAttempt;
      }

      // Create new attempt
      final response = await _supabase
          .from('Attempt')
          .insert({
            'UserId': userId,
            'QuizId': quizId,
            'StartedAt': DateTime.now().toIso8601String(),
            'Score': 0.0,
            'Time_Spent_Seconds': 0,
          })
          .select()
          .single();

      return Attempt.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to start attempt: ${e.message} (Code: ${e.code}, Details: ${e.details})');
    } catch (e) {
      throw Exception('Failed to start attempt: $e');
    }
  }

  // Submit quiz attempt with answers and calculate score
  Future<Attempt> submitAttempt({
    required int attemptId,
    required int quizId,
    required int userId,
    required Map<int, dynamic> answers, // questionId -> answer
    required DateTime startTime,
    required bool autoSubmit,
  }) async {
    try {
      // Get all questions for the quiz
      final questions = await getQuizQuestions(quizId);
      final questionIds = questions.map((q) => q.questionId).toList();

      // Get all choices for the questions
      final choicesByQuestion = await getChoicesForQuestions(questionIds);

      // Calculate score and prepare attempt answers
      double totalScore = 0.0;
      final List<Map<String, dynamic>> attemptAnswersToInsert = [];

      for (final question in questions) {
        final userAnswer = answers[question.questionId];
        double questionScore = 0.0;
        bool isCorrect = false;

        if (userAnswer != null) {
          final choices = choicesByQuestion[question.questionId] ?? [];

          switch (question.type) {
            case QuestionType.single:
              final correctChoice = choices.firstWhere((c) => c.isCorrect);
              isCorrect = userAnswer == correctChoice.choiceId;
              if (isCorrect) {
                questionScore = question.points;
              }

              attemptAnswersToInsert.add({
                'AttemptId': attemptId,
                'QuestionId': question.questionId,
                'ChoiceId': userAnswer as int,
                'Free_Text': null,
                'Is_Correct': isCorrect,
              });
              break;

            case QuestionType.multiple:
              final correctChoiceIds = choices.where((c) => c.isCorrect).map((c) => c.choiceId).toSet();
              final selectedChoiceIds = (userAnswer as List<int>).toSet();

              if (correctChoiceIds.isNotEmpty && selectedChoiceIds.isNotEmpty) {
                final correctSelected = correctChoiceIds.intersection(selectedChoiceIds).length;
                final incorrectSelected = selectedChoiceIds.difference(correctChoiceIds).length;
                final totalCorrect = correctChoiceIds.length;

                // Check if all correct answers are selected and no incorrect ones
                isCorrect = correctSelected == totalCorrect && incorrectSelected == 0;

                if (isCorrect) {
                  questionScore = question.points;
                } else {
                  // Partial scoring
                  final partialScore = (correctSelected - incorrectSelected) / totalCorrect;
                  questionScore = (partialScore.clamp(0.0, 1.0) * question.points);
                }
              }

              // Create separate answers for each selected choice
              for (final choiceId in userAnswer) {
                final choice = choices.firstWhere((c) => c.choiceId == choiceId);
                attemptAnswersToInsert.add({
                  'AttemptId': attemptId,
                  'QuestionId': question.questionId,
                  'ChoiceId': choiceId,
                  'Free_Text': null,
                  'Is_Correct': choice.isCorrect,
                });
              }
              break;

            case QuestionType.text:
              final textAnswer = userAnswer as String;
              // For text questions, do NOT auto-check - leave for manual grading
              // isCorrect will be null until teacher grades it
              
              attemptAnswersToInsert.add({
                'AttemptId': attemptId,
                'QuestionId': question.questionId,
                'ChoiceId': null,
                'Free_Text': textAnswer,
                'Is_Correct': null, // Changed from auto-checking to null for manual grading
                'Points_Awarded': null,
                'Feedback': null,
              });
              break;
          }
        } else {
          // No answer provided
          attemptAnswersToInsert.add({
            'AttemptId': attemptId,
            'QuestionId': question.questionId,
            'ChoiceId': null,
            'Free_Text': null,
            'Is_Correct': false,
            'Points_Awarded': null,
            'Feedback': null,
          });
        }

        totalScore += questionScore;
      }

      // Calculate time spent
      final endTime = DateTime.now();
      final timeSpentSeconds = endTime.difference(startTime).inSeconds;

      // Update attempt with final score and submission time
      final attemptResponse = await _supabase
          .from('Attempt')
          .update({
            'SubmittedAt': endTime.toIso8601String(),
            'Score': totalScore,
            'Time_Spent_Seconds': timeSpentSeconds,
          })
          .eq('AttemptId', attemptId)
          .select()
          .single();

      // Insert all attempt answers
      if (attemptAnswersToInsert.isNotEmpty) {
        await _supabase
            .from('AttemptAnswer')
            .insert(attemptAnswersToInsert);
      }

      // Log quiz submission
      try {
        await _activityLog.logQuizSubmission(
          userId: userId,
          quizId: quizId,
          attemptId: attemptId,
          score: totalScore,
        );
      } catch (e) {
        debugPrint('Failed to log quiz submission: $e');
      }

      return Attempt.fromJson(attemptResponse);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit attempt: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit attempt: $e');
    }
  }

  // Get attempt answers for a specific attempt
  Future<List<AttemptAnswer>> getAttemptAnswers(int attemptId) async {
    try {
      final response = await _supabase
          .from('AttemptAnswer')
          .select('*')
          .eq('AttemptId', attemptId);

      final List<AttemptAnswer> answers = [];
      for (final answerData in response) {
        answers.add(AttemptAnswer.fromJson(answerData));
      }

      return answers;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attempt answers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attempt answers: $e');
    }
  }

  // Get quiz statistics for a user
  Future<Map<String, dynamic>> getQuizStatistics(int userId) async {
    try {
      // Get all attempts for the user
      final attempts = await getUserAttempts(userId);

      // Calculate statistics
      final submittedAttempts = attempts.where((a) => a.submittedAt != null).toList();
      final totalQuizzes = submittedAttempts.map((a) => a.quizId).toSet().length;
      final totalAttempts = submittedAttempts.length;
      final averageScore = totalAttempts > 0
          ? submittedAttempts.fold<double>(0, (sum, a) => sum + a.score) / totalAttempts
          : 0.0;

      return {
        'totalQuizzes': totalQuizzes,
        'totalAttempts': totalAttempts,
        'averageScore': averageScore,
        'recentAttempts': submittedAttempts.take(5).toList(),
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch quiz statistics: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch quiz statistics: $e');
    }
  }

  // Check if user has completed a quiz
  Future<bool> hasCompletedQuiz(int userId, int quizId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, quizId);
      return attempts.any((a) => a.submittedAt != null);
    } catch (e) {
      return false;
    }
  }

  // Get latest attempt for a quiz
  Future<Attempt?> getLatestAttempt(int userId, int quizId) async {
    try {
      final attempts = await getUserQuizAttempts(userId, quizId);
      final submittedAttempts = attempts.where((a) => a.submittedAt != null).toList();
      return submittedAttempts.isNotEmpty ? submittedAttempts.first : null;
    } catch (e) {
      return null;
    }
  }

  // Get attempt details with questions and answers
  Future<Map<String, dynamic>> getAttemptDetails(int attemptId) async {
    try {
      // Get attempt
      final attemptResponse = await _supabase
          .from('Attempt')
          .select('*')
          .eq('AttemptId', attemptId)
          .single();

      final attempt = Attempt.fromJson(attemptResponse);

      // Get quiz
      final quiz = await getQuizById(attempt.quizId);

      // Get questions
      final questions = await getQuizQuestions(attempt.quizId);

      // Get choices for all questions
      final questionIds = questions.map((q) => q.questionId).toList();
      final choicesByQuestion = await getChoicesForQuestions(questionIds);

      // Get attempt answers
      final answers = await getAttemptAnswers(attemptId);

      // Group answers by question
      final Map<int, List<AttemptAnswer>> answersByQuestion = {};
      for (final answer in answers) {
        if (!answersByQuestion.containsKey(answer.questionId)) {
          answersByQuestion[answer.questionId] = [];
        }
        answersByQuestion[answer.questionId]!.add(answer);
      }

      return {
        'attempt': attempt,
        'quiz': quiz,
        'questions': questions,
        'choices': choicesByQuestion,
        'answers': answersByQuestion,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attempt details: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attempt details: $e');
    }
  }

  // Get all quiz results for a user with an optimized query
  Future<List<Map<String, dynamic>>> getAllQuizResults(int userId) async {
    try {
      // Fetch all completed attempts with quiz and course data in a single query
      final response = await _supabase
          .from('Attempt')
          .select('''
            *,
            Quiz!QuizId (
              *,
              Course!CourseId (
                CourseId,
                Name,
                Code
              )
            )
          ''')
          .eq('UserId', userId)
          .not('SubmittedAt', 'is', null)
          .order('SubmittedAt', ascending: false);

      debugPrint('getAllQuizResults: Fetched ${response.length} attempts');

      if (response.isEmpty) {
        return [];
      }

      // Extract all unique quiz IDs and attempt IDs
      final quizIds = <int>{};
      final attemptIds = <int>[];
      
      for (final attemptData in response) {
        final attempt = Attempt.fromJson(attemptData);
        quizIds.add(attempt.quizId);
        attemptIds.add(attempt.attemptId);
      }

      debugPrint('getAllQuizResults: Processing ${quizIds.length} unique quizzes and ${attemptIds.length} attempts');

      // Bulk fetch questions for all quizzes
      final questionsResponse = await _supabase
          .from('Question')
          .select('QuizId, QuestionId, Points')
          .inFilter('QuizId', quizIds.toList());

      debugPrint('getAllQuizResults: Fetched ${questionsResponse.length} questions');

      // Group questions by quiz ID
      final Map<int, List<Map<String, dynamic>>> questionsByQuiz = {};
      for (final q in questionsResponse) {
        final quizId = q['QuizId'] as int;
        if (!questionsByQuiz.containsKey(quizId)) {
          questionsByQuiz[quizId] = [];
        }
        questionsByQuiz[quizId]!.add(q);
      }

      // Bulk fetch answers for all attempts
      final answersResponse = await _supabase
          .from('AttemptAnswer')
          .select('AttemptId, Is_Correct')
          .inFilter('AttemptId', attemptIds);

      debugPrint('getAllQuizResults: Fetched ${answersResponse.length} answers');

      // Group answers by attempt ID
      final Map<int, List<Map<String, dynamic>>> answersByAttempt = {};
      for (final a in answersResponse) {
        final attemptId = a['AttemptId'] as int;
        if (!answersByAttempt.containsKey(attemptId)) {
          answersByAttempt[attemptId] = [];
        }
        answersByAttempt[attemptId]!.add(a);
      }

      // Build results
      final List<Map<String, dynamic>> results = [];

      for (final attemptData in response) {
        try {
          final attempt = Attempt.fromJson(attemptData);
          
          // Check if Quiz data exists
          if (attemptData['Quiz'] == null) {
            debugPrint('getAllQuizResults: Quiz data is null for attempt ${attempt.attemptId}');
            continue;
          }
          
          final quizData = attemptData['Quiz'] as Map<String, dynamic>;
          
          // Check if Course data exists
          if (quizData['Course'] == null) {
            debugPrint('getAllQuizResults: Course data is null for quiz ${attempt.quizId}');
            continue;
          }
          
          final courseData = quizData['Course'] as Map<String, dynamic>;

          final questions = questionsByQuiz[attempt.quizId] ?? [];
          final answers = answersByAttempt[attempt.attemptId] ?? [];

          final totalQuestions = questions.length;
          final totalPoints = questions.fold<double>(
            0.0,
            (sum, q) => sum + (q['Points'] as num).toDouble(),
          );
          final correctAnswers = answers.where((a) => a['Is_Correct'] == true).length;
          
          double percentage;
          if (totalPoints == 0) {
            percentage = 0.0;
          } else if (attempt.score > totalPoints) {
            percentage = attempt.score.clamp(0.0, 100.0);
          } else {
            percentage = (attempt.score / totalPoints) * 100;
          }
          
          percentage = percentage.clamp(0.0, 100.0);

          results.add({
            'attempt': attempt,
            'quiz': Quiz.fromJson(quizData),
            'course': {
              'courseId': courseData['CourseId'],
              'name': courseData['Name'],
              'code': courseData['Code'],
            },
            'percentage': percentage,
            'correctAnswers': correctAnswers,
            'totalQuestions': totalQuestions,
          });
        } catch (e) {
          debugPrint('Error processing attempt: $e');
          continue;
        }
      }

      debugPrint('getAllQuizResults: Successfully processed ${results.length} results');
      return results;
    } on PostgrestException catch (e) {
      debugPrint('getAllQuizResults: PostgrestException - ${e.message}');
      throw Exception('Failed to fetch quiz results: ${e.message}');
    } catch (e) {
      debugPrint('getAllQuizResults: Exception - $e');
      throw Exception('Failed to fetch quiz results: $e');
    }
  }

  // Grade a text answer manually
  Future<void> gradeTextAnswer({
    required int attemptAnswerId,
    required double pointsAwarded,
    String? feedback,
  }) async {
    try {
      final isCorrect = pointsAwarded > 0;
      
      await _supabase
          .from('AttemptAnswer')
          .update({
            'Is_Correct': isCorrect,
            'Points_Awarded': pointsAwarded,
            'Feedback': feedback,
          })
          .eq('AttemptAnswerId', attemptAnswerId);
      
      // Recalculate attempt score
      final answerResponse = await _supabase
          .from('AttemptAnswer')
          .select('AttemptId')
          .eq('AttemptAnswerId', attemptAnswerId)
          .single();
      
      final attemptId = answerResponse['AttemptId'] as int;
      await _recalculateAttemptScore(attemptId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to grade answer: ${e.message}');
    } catch (e) {
      throw Exception('Failed to grade answer: $e');
    }
  }

  // Recalculate attempt score after grading
  Future<void> _recalculateAttemptScore(int attemptId) async {
    try {
      // Get all answers for this attempt
      final answers = await getAttemptAnswers(attemptId);
      
      // Calculate total score
      double totalScore = 0.0;
      for (final answer in answers) {
        if (answer.pointsAwarded != null) {
          // Use manually awarded points for text answers
          totalScore += answer.pointsAwarded!;
        } else if (answer.isCorrect == true) {
          // For auto-graded questions, get the question points
          final questionResponse = await _supabase
              .from('Question')
              .select('Points')
              .eq('QuestionId', answer.questionId)
              .single();
          
          totalScore += (questionResponse['Points'] as num).toDouble();
        }
      }
      
      // Update attempt score
      await _supabase
          .from('Attempt')
          .update({'Score': totalScore})
          .eq('AttemptId', attemptId);
    } catch (e) {
      debugPrint('Failed to recalculate attempt score: $e');
      rethrow;
    }
  }

  // Get attempts that need grading for a quiz
  Future<List<Map<String, dynamic>>> getAttemptsNeedingGrading(int quizId) async {
    try {
      // Get all submitted attempts for this quiz
      final attemptsResponse = await _supabase
          .from('Attempt')
          .select('''
            *,
            User:UserId (
              UserId,
              FullName,
              Email
            ),
            Student:UserId (
              UserId,
              StudentId,
              Section
            )
          ''')
          .eq('QuizId', quizId)
          .not('SubmittedAt', 'is', null)
          .order('SubmittedAt', ascending: false);

      final List<Map<String, dynamic>> attemptsNeedingGrading = [];

      for (final attemptData in attemptsResponse) {
        final attempt = Attempt.fromJson(attemptData);
        
        // Get answers for this attempt
        final answers = await getAttemptAnswers(attempt.attemptId);
        
        // Check if any text answers need grading
        final needsGrading = answers.any((a) => a.needsGrading);
        
        if (needsGrading) {
          attemptsNeedingGrading.add({
            'attempt': attempt,
            'user': attemptData['User'],
            'student': attemptData['Student'],
            'answers': answers,
          });
        }
      }

      return attemptsNeedingGrading;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch attempts needing grading: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch attempts needing grading: $e');
    }
  }
}