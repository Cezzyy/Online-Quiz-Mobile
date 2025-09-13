class Teacher {
  final int userId;
  final String? department;

  const Teacher({
    required this.userId,
    this.department,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      userId: json['UserId'] as int,
      department: json['Department'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Department': department,
    };
  }

  Teacher copyWith({
    int? userId,
    String? department,
  }) {
    return Teacher(
      userId: userId ?? this.userId,
      department: department ?? this.department,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Teacher && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'Teacher(userId: $userId, department: $department)';
  }
}