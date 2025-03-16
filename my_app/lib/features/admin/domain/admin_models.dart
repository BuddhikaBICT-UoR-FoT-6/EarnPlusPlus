class UserAccount {
  final int id;
  final String email;
  final String role;
  final DateTime createdAt;

  const UserAccount({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        id: (json['id'] as num).toInt(),
        email: json['email'].toString(),
        role: (json['role'] ?? 'user').toString(),
        createdAt: DateTime.parse(json['created_at'].toString()),
      );
}

class AdminSummary {
  final int users;
  final int investments;
  final double totalAmount;

  const AdminSummary({
    required this.users,
    required this.investments,
    required this.totalAmount,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) => AdminSummary(
        users: (json['users'] as num).toInt(),
        investments: (json['investments'] as num).toInt(),
        totalAmount: ((json['total_amount'] ?? 0) as num).toDouble(),
      );
}

class SuperAdminSummary {
  final int users;
  final int investments;
  final Map<String, int> roles;

  const SuperAdminSummary({
    required this.users,
    required this.investments,
    required this.roles,
  });

  factory SuperAdminSummary.fromJson(Map<String, dynamic> json) {
    final roleJson = (json['roles'] as Map<String, dynamic>? ?? {});
    return SuperAdminSummary(
      users: (json['users'] as num).toInt(),
      investments: (json['investments'] as num).toInt(),
      roles: roleJson.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }
}
