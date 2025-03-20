import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/admin/data/admin_repository.dart';
import 'package:my_app/features/admin/domain/admin_models.dart';
import 'package:my_app/features/admin/presentation/admin_controller.dart';
import 'package:my_app/screens/admin_dashboard_page.dart';

class _FakeAdminRepository extends AdminRepository {
  @override
  Future<UserAccount> fetchMe() async {
    return UserAccount(
      id: 1,
      email: 'admin@example.com',
      role: 'admin',
      createdAt: DateTime(2025, 3, 2),
    );
  }

  @override
  Future<AdminSummary> fetchAdminSummary() async {
    return const AdminSummary(users: 10, investments: 20, totalAmount: 5000.0);
  }

  @override
  Future<List<UserAccount>> fetchUsers() async {
    return [
      UserAccount(
        id: 2,
        email: 'user@example.com',
        role: 'user',
        createdAt: DateTime(2025, 3, 3),
      ),
    ];
  }
}

void main() {
  testWidgets('renders admin dashboard summary and users', (tester) async {
    final controller = AdminController(repository: _FakeAdminRepository());
    await controller.loadAdminDashboard();

    await tester.pumpWidget(
      MaterialApp(home: AdminDashboardPage(controller: controller)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Users'), findsWidgets);
    expect(find.text('user@example.com'), findsOneWidget);
  });
}
