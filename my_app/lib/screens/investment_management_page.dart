import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../core/utils/decimal_format.dart';
import '../features/investments/domain/investment.dart';
import '../features/investments/presentation/investment_controller.dart';

class InvestmentManagementPage extends StatelessWidget {
  const InvestmentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvestmentController()..load(),
      child: const _InvestmentManagementView(),
    );
  }
}

class _InvestmentManagementView extends StatelessWidget {
  const _InvestmentManagementView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvestmentController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Investments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isMutating
            ? null
            : () => _openForm(context, controller: controller),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            if (controller.state == InvestmentLoadState.loading)
              const LinearProgressIndicator(),
            if (controller.actionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  controller.actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: controller.investments.isEmpty
                  ? const Center(child: Text('No investments yet'))
                  : ListView.separated(
                      itemCount: controller.investments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final inv = controller.investments[index];
                        return ListTile(
                          title: Text(inv.asset),
                          subtitle: Text(
                            '${inv.date.toIso8601String().split('T').first} • ${decimalToFixed(inv.amount, fractionDigits: 2)}',
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: inv.id == null || controller.isMutating
                                    ? null
                                    : () => _openForm(
                                          context,
                                          controller: controller,
                                          existing: inv,
                                        ),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: inv.id == null || controller.isMutating
                                    ? null
                                    : () => _confirmDelete(
                                          context,
                                          controller: controller,
                                          id: inv.id!,
                                        ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required InvestmentController controller,
    required int id,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete investment'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await controller.deleteInvestment(id);
  }

  Future<void> _openForm(
    BuildContext context, {
    required InvestmentController controller,
    Investment? existing,
  }) async {
    final assetController = TextEditingController(text: existing?.asset ?? '');
    final amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add investment' : 'Edit investment'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: assetController,
                      decoration: const InputDecoration(labelText: 'Asset'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Asset is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a positive amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${selectedDate.toIso8601String().split('T').first}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave != true) {
      assetController.dispose();
      amountController.dispose();
      return;
    }

    if (existing == null) {
      await controller.addInvestment(
        date: selectedDate,
        asset: assetController.text.trim(),
        amount: amountController.text.trim(),
      );
    } else if (existing.id != null) {
      await controller.updateInvestment(
        id: existing.id!,
        date: selectedDate,
        asset: assetController.text.trim(),
        amount: amountController.text.trim(),
      );
    }

    assetController.dispose();
    amountController.dispose();
  }
}
