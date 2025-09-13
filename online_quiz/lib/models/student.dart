class Student {
  final int userId;
  final String studentId;
  final int? yearLevel;
  final String? section;
  final String? course;

  const Student({
    required this.userId,
    required this.studentId,
    this.yearLevel,
    this.section,
    this.course,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      userId: json['UserId'] as int,
      studentId: json['StudentId'] as String,
      yearLevel: json['Year_Level'] as int?,
      section: json['Section'] as String?,
      course: json['Course'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'StudentId': studentId,
      'Year_Level': yearLevel,
      'Section': section,
      'Course': course,
    };
  }

  Student copyWith({
    int? userId,
    String? studentId,
    int? yearLevel,
    String? section,
    String? course,
  }) {
    return Student(
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      course: course ?? this.course,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Student && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'Student(userId: $userId, yearLevel: $yearLevel, section: $section, course: $course)';
  }
}