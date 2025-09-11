class UserRole {
  final int userId;
  final int roleId;

  const UserRole({
    required this.userId,
    required this.roleId,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      userId: json['UserId'] as int,
      roleId: json['RoleId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'RoleId': roleId,
    };
  }

  UserRole copyWith({
    int? userId,
    int? roleId,
  }) {
    return UserRole(
      userId: userId ?? this.userId,
      roleId: roleId ?? this.roleId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRole && 
           other.userId == userId && 
           other.roleId == roleId;
  }

  @override
  int get hashCode => Object.hash(userId, roleId);

  @override
  String toString() {
    return 'UserRole(userId: $userId, roleId: $roleId)';
  }
}