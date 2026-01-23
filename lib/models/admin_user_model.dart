/// Simple model untuk admin user data
class AdminUserModel {
  final String email;
  final String role;
  final DateTime? lastLogin;
  final List<String> permissions;

  AdminUserModel({
    required this.email,
    required this.role,
    this.lastLogin,
    this.permissions = const ['read', 'write', 'delete'],
  });

  /// Convert dari Map ke AdminUserModel
  factory AdminUserModel.fromMap(Map<String, dynamic> map) {
    return AdminUserModel(
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'admin',
      lastLogin: map['last_login'] != null
          ? DateTime.parse(map['last_login'] as String)
          : null,
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'] as List)
          : ['read', 'write', 'delete'],
    );
  }

  /// Convert AdminUserModel ke Map
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'last_login': lastLogin?.toIso8601String(),
      'permissions': permissions,
    };
  }
}
