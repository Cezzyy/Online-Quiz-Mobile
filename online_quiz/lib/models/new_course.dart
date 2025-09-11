class Course {
  final int courseId;
  final String code;
  final String name;
  final int instructorUserId;

  const Course({
    required this.courseId,
    required this.code,
    required this.name,
    required this.instructorUserId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['CourseId'] as int,
      code: json['Code'] as String,
      name: json['Name'] as String,
      instructorUserId: json['Instructor_UserId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CourseId': courseId,
      'Code': code,
      'Name': name,
      'Instructor_UserId': instructorUserId,
    };
  }

  Course copyWith({
    int? courseId,
    String? code,
    String? name,
    int? instructorUserId,
  }) {
    return Course(
      courseId: courseId ?? this.courseId,
      code: code ?? this.code,
      name: name ?? this.name,
      instructorUserId: instructorUserId ?? this.instructorUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.courseId == courseId;
  }

  @override
  int get hashCode => courseId.hashCode;

  @override
  String toString() {
    return 'Course(courseId: $courseId, code: $code, name: $name, instructorUserId: $instructorUserId)';
  }
}