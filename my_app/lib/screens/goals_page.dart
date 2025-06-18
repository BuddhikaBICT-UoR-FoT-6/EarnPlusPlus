import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/animated_widgets.dart';
import '../features/goals/domain/goal_dto.dart';
import '../features/goals/presentation/goal_controller.dart';
import 'login_page.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoalController()..load(),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatefulWidget {
  const _GoalsView();

  @override
  State<_GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<_GoalsView> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GoalController>();

    if (controller.state == GoalLoadState.unauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (r) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Goals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isMutating ? null : () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: controller.state == GoalLoadState.loading
            ? const Center(child: CircularProgressIndicator())
            : controller.state == GoalLoadState.empty
                ? const Center(child: Text('No goals yet! Create one.'))
                : controller.state == GoalLoadState.error
                    ? Center(
                        child: Text(
                          controller.error ?? 'An error occurred',
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: controller.goals.length,
                        itemBuilder: (context, index) {
                          final goal = controller.goals[index];
                          return AnimatedFadeIn(
                            delay: Duration(milliseconds: 50 * index),
                            child: AnimatedSlideIn(
                              begin: const Offset(0.0, 0.5),
                              delay: Duration(milliseconds: 50 * index),
                              child: _GoalCard(
                                goal: goal,
                                onEdit: () => _openForm(context, existing: goal),
                                onDelete: () => _confirmDelete(context, goal.id),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GoalController>().deleteGoal(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {GoalDto? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title);
    final targetCtrl = TextEditingController(text: existing?.targetAmount.toString());
    final currentCtrl = TextEditingController(text: existing?.currentAmount.toString());
    final formKey = GlobalKey<FormState>();

    final controller = context.read<GoalController>();

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'New Goal' : 'Edit Goal'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g. New Car'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: targetCtrl,
                        decoration: const InputDecoration(labelText: 'Target Amount (\$)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: currentCtrl,
                        decoration: const InputDecoration(labelText: 'Current Saved (\$)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Must be a number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                  onPressed: controller.isMutating
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          
                          if (existing == null) {
                            await controller.addGoal(
                              title: titleCtrl.text.trim(),
                              targetAmount: double.parse(targetCtrl.text.trim()),
                              currentAmount: double.parse(currentCtrl.text.trim()),
                            );
                          } else {
                            await controller.updateGoal(
                              id: existing.id,
                              title: titleCtrl.text.trim(),
                              targetAmount: double.parse(targetCtrl.text.trim()),
                              currentAmount: double.parse(currentCtrl.text.trim()),
                            );
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: controller.isMutating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    targetCtrl.dispose();
    currentCtrl.dispose();
  }
}

class _GoalCard extends StatelessWidget {
  final GoalDto goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({required this.goal, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete, size: 20, color: AppColors.error), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}'),
                Text('${(progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppColors.surfaceHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1.0 ? Colors.green : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
