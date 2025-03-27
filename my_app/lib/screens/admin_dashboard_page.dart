import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../features/admin/presentation/admin_controller.dart';

class AdminDashboardPage extends StatelessWidget {
  final AdminController? controller;

  const AdminDashboardPage({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    // the build method checks whether a controller was injected (for testing)
    // or whether the widget should create and manage its own controller instance.
    // This dual-path pattern enables dependency injection for widget tests while
    // preserving the default production behavior of lazy initialization. The
    // controller is provided to the widget tree via ChangeNotifierProvider so
    // child widgets can watch it for state changes.
    if (controller != null) {
      return ChangeNotifierProvider<AdminController>.value(
        value: controller!,
        child: const _AdminDashboardView(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AdminController()..loadAdminDashboard(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AdminController controller) {
    // the _buildBody method is intentionally structured as a state machine where
    // each branch corresponds to a distinct loading or error state. This approach
    // keeps the render logic clear and testable: if loading, show a progress bar;
    // if forbidden or unauthorized, display a permission error; if successful, show
    // the dashboard. Each state branch is mutually exclusive and renders appropriate
    // feedback so users always know what the app is doing.
    if (controller.state == AdminLoadState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.state == AdminLoadState.forbidden) {
      return const Center(child: Text('You do not have admin access.'));
    }

    if (controller.state == AdminLoadState.unauthorized) {
      return const Center(child: Text('Session expired. Please login again.'));
    }

    if (controller.state == AdminLoadState.error) {
      return Center(child: Text(controller.error ?? 'Failed to load data'));
    }

    final summary = controller.adminSummary;
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
              label: 'Total Amount',
              value: summary.totalAmount.toStringAsFixed(2),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Users', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Expanded(
          child: ListView.separated(
            itemCount: controller.users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = controller.users[index];
              return ListTile(
                dense: true,
                title: Text(user.email),
                subtitle: Text(user.role),
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
    // the _SummaryCard is a compact, reusable widget that displays a single
    // metric (e.g., user count, investment total) in a consistent card-based
    // layout. By extracting this into a separate widget, we reduce code duplication
    // and ensure that all metric cards maintain uniform styling, typography, and
    // spacing across the admin and superadmin dashboards.
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
