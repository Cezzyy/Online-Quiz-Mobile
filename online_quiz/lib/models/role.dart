class Role {
  final int roleId;
  final String name;

  const Role({
    required this.roleId,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      roleId: json['RoleId'] as int,
      name: json['Name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RoleId': roleId,
      'Name': name,
    };
  }

  Role copyWith({
    int? roleId,
    String? name,
  }) {
    return Role(
      roleId: roleId ?? this.roleId,
      name: name ?? this.name,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role && other.roleId == roleId;
  }

  @override
  int get hashCode => roleId.hashCode;

  @override
  String toString() {
    return 'Role(roleId: $roleId, name: $name)';
  }

  // Predefined role constants
  static const Role admin = Role(roleId: 1, name: 'Admin');
  static const Role teacher = Role(roleId: 2, name: 'Teacher');
  static const Role student = Role(roleId: 3, name: 'Student');

  bool get isAdmin => name == 'Admin';
  bool get isTeacher => name == 'Teacher';
  bool get isStudent => name == 'Student';
}