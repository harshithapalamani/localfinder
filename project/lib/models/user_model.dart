enum UserRole { worker, admin, employer }
enum UserStatus { pending, approved, rejected }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String village;
  final UserRole role;
  final UserStatus status;
  final List<String> skills;
  final String? description;
  final DateTime createdAt;
  final DateTime? approvedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.village,
    required this.role,
    required this.status,
    required this.skills,
    this.description,
    required this.createdAt,
    this.approvedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'village': village,
      'role': role.name,
      'status': status.name,
      'skills': skills,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      village: json['village'],
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      status: UserStatus.values.firstWhere((e) => e.name == json['status']),
      skills: List<String>.from(json['skills']),
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? village,
    UserRole? role,
    UserStatus? status,
    List<String>? skills,
    String? description,
    DateTime? createdAt,
    DateTime? approvedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      village: village ?? this.village,
      role: role ?? this.role,
      status: status ?? this.status,
      skills: skills ?? this.skills,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}