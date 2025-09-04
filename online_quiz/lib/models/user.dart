import 'course.dart';
import 'notification_item.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final List<Course> courses;
  final List<NotificationItem> notifications;
  final String bio;
  final String phoneNumber;
  final String emergencyContact;
  final String profileImageUrl;
  final String degree;
  final String userType;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.courses,
    required this.notifications,
    required this.bio,
    required this.phoneNumber,
    required this.emergencyContact,
    required this.profileImageUrl,
    required this.degree,
    required this.userType,
  });

  // Getter for the primary course (first course if available)
  Course? get course => courses.isNotEmpty ? courses.first : null;
}