import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/admin/data/admin_repository.dart';
import 'package:my_app/features/admin/domain/admin_models.dart';
import 'package:my_app/features/admin/presentation/admin_controller.dart';
import 'package:my_app/screens/superadmin_dashboard_page.dart';

class _FakeSuperAdminRepository extends AdminRepository {
  @override
  Future<UserAccount> fetchMe() async {
    return UserAccount(
      id: 1,
      email: 'super@example.com',
      role: 'superadmin',
      createdAt: DateTime(2025, 3, 2),
    );
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

  @override
  Future<SuperAdminSummary> fetchSuperAdminSummary() async {
    return const SuperAdminSummary(
      users: 10,
      investments: 20,
      roles: {'user': 8, 'admin': 1, 'superadmin': 1},
    );
  }
}

void main() {
  testWidgets('renders superadmin dashboard and role manager', (tester) async {
    final controller = AdminController(repository: _FakeSuperAdminRepository());
    await controller.loadSuperAdminDashboard();

    await tester.pumpWidget(
      MaterialApp(home: SuperAdminDashboardPage(controller: controller)),
    );

    await tester.pumpAndSettle();

    expect(find.text('Superadmin Dashboard'), findsOneWidget);
    expect(find.text('Manage User Roles'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
  });
}
