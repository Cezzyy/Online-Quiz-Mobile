class User {
  final int userId;
  final String email;
  final String? passwordHash;
  final String fullName;
  final String status;
  final String contactNumber;
  final String emergencyContactNumber;
  final String emergencyContactPerson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;

  const User({
    required this.userId,
    required this.email,
    this.passwordHash,
    required this.fullName,
    required this.status,
    this.contactNumber = '',
    this.emergencyContactNumber = '',
    this.emergencyContactPerson = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['UserId'] as int,
      email: json['Email'] as String,
      passwordHash: json['PasswordHash'] as String?, 
      fullName: json['FullName'] as String,
      status: json['Status'] as String,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      updatedAt: DateTime.parse(json['UpdatedAt'] as String),
      contactNumber: json['ContactNumber'] as String? ?? '',
      emergencyContactNumber: json['EmergencyContactNumber'] as String? ?? '',
      emergencyContactPerson: json['EmergencyContactPerson'] as String? ?? '',
      createdBy: json['CreatedBy'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'UserId': userId,
      'Email': email,
      'PasswordHash': passwordHash, 
      'FullName': fullName,
      'Status': status,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
      'ContactNumber': contactNumber,
      'EmergencyContactNumber': emergencyContactNumber,
      'EmergencyContactPerson': emergencyContactPerson,
      'CreatedBy': createdBy,
    };
  }

  User copyWith({
    int? userId,
    String? email,
    String? passwordHash,
    String? fullName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactNumber,
    String? emergencyContactNumber,
    String? emergencyContactPerson,
    int? createdBy,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactNumber: contactNumber ?? this.contactNumber,
      emergencyContactNumber: emergencyContactNumber ?? this.emergencyContactNumber,
      emergencyContactPerson: emergencyContactPerson ?? this.emergencyContactPerson,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  bool get isActive => status == 'Active';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'User(userId: $userId, email: $email, fullName: $fullName, status: $status)';
  }
}