import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../features/admin/presentation/admin_controller.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
