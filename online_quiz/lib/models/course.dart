class Course {
  final int courseId;
  final String code;
  final String name;
  final int instructorUserId;
  final String status;
  final String? category;
  final String? section;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int createdBy;

  const Course({
    required this.courseId,
    required this.code,
    required this.name,
    required this.instructorUserId,
    this.status = 'Active',
    this.category,
    this.section,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['CourseId'] as int,
      code: json['Code'] as String,
      name: json['Name'] as String,
      instructorUserId: json['Instructor_UserId'] as int,
      status: json['Status'] as String? ?? 'Active',
      category: json['Category'] as String?,
      section: json['Section'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      createdBy: json['CreatedBy'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CourseId': courseId,
      'Code': code,
      'Name': name,
      'Instructor_UserId': instructorUserId,
      'Status': status,
      'Category': category,
      'Section': section,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'CreatedBy': createdBy,
    };
  }

  Course copyWith({
    int? courseId,
    String? code,
    String? name,
    int? instructorUserId,
    String? status,
    String? category,
    String? section,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
  }) {
    return Course(
      courseId: courseId ?? this.courseId,
      code: code ?? this.code,
      name: name ?? this.name,
      instructorUserId: instructorUserId ?? this.instructorUserId,
      status: status ?? this.status,
      category: category ?? this.category,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Helper methods
  bool get isActive => status.toLowerCase() == 'active';
  bool get isInactive => status.toLowerCase() == 'inactive';
  bool get isArchived => status.toLowerCase() == 'archived';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.courseId == courseId;
  }

  @override
  int get hashCode => courseId.hashCode;

  @override
  String toString() {
    return 'Course(courseId: $courseId, code: $code, name: $name, instructorUserId: $instructorUserId, status: $status, category: $category, section: $section, createdAt: $createdAt, updatedAt: $updatedAt, createdBy: $createdBy)';
  }
}