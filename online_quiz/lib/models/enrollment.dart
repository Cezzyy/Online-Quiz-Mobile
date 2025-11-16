class Enrollment {
  final int enrollmentId;
  final int userId;
  final int courseId;
  final DateTime enrolledAt;
  final String? section;
  final int enrolledBy;

  const Enrollment({
    required this.enrollmentId,
    required this.userId,
    required this.courseId,
    required this.enrolledAt,
    this.section,
    required this.enrolledBy,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      enrollmentId: json['EnrollmentId'] as int,
      userId: json['UserId'] as int,
      courseId: json['CourseId'] as int,
      enrolledAt: DateTime.parse(json['EnrolledAt'] as String),
      section: json['Section'] as String?,
      enrolledBy: json['EnrolledBy'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EnrollmentId': enrollmentId,
      'UserId': userId,
      'CourseId': courseId,
      'EnrolledAt': enrolledAt.toIso8601String(),
      'Section': section,
      'EnrolledBy': enrolledBy,
    };
  }

  Enrollment copyWith({
    int? enrollmentId,
    int? userId,
    int? courseId,
    DateTime? enrolledAt,
    String? section,
    int? enrolledBy,
  }) {
    return Enrollment(
      enrollmentId: enrollmentId ?? this.enrollmentId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      section: section ?? this.section,
      enrolledBy: enrolledBy ?? this.enrolledBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Enrollment && other.enrollmentId == enrollmentId;
  }

  @override
  int get hashCode => enrollmentId.hashCode;

  @override
  String toString() {
    return 'Enrollment(enrollmentId: $enrollmentId, userId: $userId, courseId: $courseId, enrolledAt: $enrolledAt)';
  }
}