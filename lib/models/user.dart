enum UserRole { student, institutionAdmin, verifier }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? studentId;
  final String? institutionId;
  final String? institutionName;
  final String? avatarUrl;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
    this.institutionId,
    this.institutionName,
    this.avatarUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'studentId': studentId,
    'institutionId': institutionId,
    'institutionName': institutionName,
    'avatarUrl': avatarUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: UserRole.values.firstWhere((e) => e.name == json['role']),
    studentId: json['student_id'],
    institutionId: json['institutionId'],
    institutionName: json['institutionName'],
    avatarUrl: json['avatarUrl'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  static UserRole _stringToRole(String role) {
    switch (role) {
      case 'institution_admin':
        return UserRole.institutionAdmin;
      case 'graduate':
        return UserRole.student;
      case 'verifier':
        return UserRole.verifier;
      default:
        return UserRole.verifier;
    }
  }

  bool get isStudent => role == UserRole.student;
  bool get isInstitutionAdmin => role == UserRole.institutionAdmin;
  bool get isVerifier => role == UserRole.verifier;
}
