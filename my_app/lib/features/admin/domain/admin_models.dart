// The UserAccount class represents a user record retrieved from the admin API,
// including the user's ID, email, assigned role, and account creation timestamp.
// This model is used throughout admin and superadmin dashboards to display user
// information and enable role management. The fromJson factory constructor maps
// API responses to strongly-typed Dart objects, ensuring type safety and providing
// default values (e.g., 'user' role) for missing fields.
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
    // normalizes backend payload into strongly typed UI model fields.
    id: (json['id'] as num).toInt(),
    email: json['email'].toString(),
    role: (json['role'] ?? 'user').toString(),
    createdAt: DateTime.parse(json['created_at'].toString()),
  );
}

// The AdminSummary class holds aggregate metrics displayed in the admin dashboard,
// including counts of total users, total investments, and the total amount invested
// across all users. These metrics are fetched via the /admin/dashboard API endpoint
// and rendered as summary cards at the top of the admin interface, providing
// quick visibility into the scale of the application's user base and investment activity.
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

// The SuperAdminSummary class extends the admin summary with a detailed breakdown
// of users by role (user, admin, superadmin), enabling superadmin-only governance
// views. This role-distribution data helps superadmins understand the administrative
// hierarchy and ensure appropriate privilege distribution across the system.
// The fromJson factory safely handles missing role entries by defaulting them to zero.
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
