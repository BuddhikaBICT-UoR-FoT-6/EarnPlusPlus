import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../features/admin/presentation/admin_controller.dart';

class SuperAdminDashboardPage extends StatelessWidget {
  final AdminController? controller;

  const SuperAdminDashboardPage({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    // the build method follows the same dependency-injection pattern as admin_dashboard_page,
    // accepting an optional controller for testing while defaulting to lazy initialization
    // in production. This symmetry ensures that both dashboard types behave consistently
    // and can be tested using the same patterns and fake-repository approach.
    if (controller != null) {
      return ChangeNotifierProvider<AdminController>.value(
        value: controller!,
        child: const _SuperAdminDashboardView(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AdminController()..loadSuperAdminDashboard(),
      child: const _SuperAdminDashboardView(),
    );
  }
}

class _SuperAdminDashboardView extends StatelessWidget {
  const _SuperAdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Superadmin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminController controller) {
    // the _buildBody method explicitly branches on each state to provide clear,
    // role-specific error messages and permission feedback. When access is denied
    // (403 Forbidden), it displays "You do not have superadmin access." When the
    // session expires (401 Unauthorized), it prompts re-login. This explicit handling
    // gives users actionable feedback and helps distinguish between authorization
    // and authentication failures at a glance.
    if (controller.state == AdminLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.state == AdminLoadState.forbidden) {
      return const Center(child: Text('You do not have superadmin access.'));
    }

    if (controller.state == AdminLoadState.unauthorized) {
      return const Center(child: Text('Session expired. Please login again.'));
    }

    if (controller.state == AdminLoadState.error) {
      return Center(child: Text(controller.error ?? 'Failed to load data'));
    }

    final summary = controller.superAdminSummary;
    if (summary == null) {
      return const Center(child: Text('No summary available.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SummaryCard(label: 'Users', value: summary.users.toString()),
            _SummaryCard(
              label: 'Investments',
              value: summary.investments.toString(),
            ),
            _SummaryCard(
              label: 'Admins',
              value: (summary.roles['admin'] ?? 0).toString(),
            ),
            _SummaryCard(
              label: 'Superadmins',
              value: (summary.roles['superadmin'] ?? 0).toString(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (controller.error != null)
          Text(
            controller.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Text(
          'Manage User Roles',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ListView.separated(
            itemCount: controller.users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = controller.users[index];
              return ListTile(
                title: Text(user.email),
                subtitle: Text(
                  'Created ${user.createdAt.toIso8601String().split('T').first}',
                ),
                trailing: DropdownButton<String>(
                  value: user.role,
                  onChanged: controller.roleUpdateInProgress
                      ? null
                      : (value) {
                          // the guard clause prevents redundant updates when the dropdown
                          // selection hasn't changed, avoiding unnecessary network requests
                          // and keeping the UI responsive. This is a common pattern for
                          // dropdowns that might fire onChanged even when the value is the same.
                          if (value == null || value == user.role) {
                            return;
                          }
                          controller.changeRole(userId: user.id, role: value);
                        },
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('user')),
                    DropdownMenuItem(value: 'admin', child: Text('admin')),
                    DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('superadmin'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    // the _SummaryCard widget presents metric labels and values in a compact,
    // visually distinguishable card format. Extracting this shared presentation
    // logic ensures consistency between admin and superadmin metric displays and
    // makes future styling changes easy to implement across all dashboard cards.
    return Card(
      child: SizedBox(
        width: 150,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
