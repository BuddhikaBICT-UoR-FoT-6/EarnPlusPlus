import 'package:flutter/material.dart'; // Flutter framework for building UI
import 'package:provider/provider.dart'; // Provider package for state management

import '../core/constants/app_spacing.dart';
import '../core/utils/decimal_format.dart';
import '../features/investments/domain/investment.dart';
import '../features/investments/presentation/investment_controller.dart';

// The InvestmentManagementPage is a stateless widget that displays a list of
// investments and allows the user to add, edit, or delete investments. It uses
// an optional InvestmentController to manage the state of the investments.
// If a controller is provided, it uses that controller; otherwise, it creates a
// new instance of InvestmentController and loads the investments. The page includes
// a floating action button to add new investments.
class InvestmentManagementPage extends StatelessWidget {
  final InvestmentController? controller; // optional controller for managing
  // investment state and actions, allowing for dependency injection and easier
  // testing by providing a custom controller instance when needed

  const InvestmentManagementPage({
    super.key,
    this.controller,
  }); // constructor for
  // the InvestmentManagementPage, allowing an optional controller to be passed in,
  // which can be used to manage the state of the investments and perform actions
  // such as loading, adding, editing, or deleting investments. If no controller is
  // provided, the page will create its own instance of InvestmentController and
  // load the investments when it is built.

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      // if a controller is provided, use it to manage the state of the investments
      // and provide it to the widget tree using ChangeNotifierProvider, allowing
      // the UI to react to changes in the investment data and update accordingly
      // when the controller's state changes
      return ChangeNotifierProvider<InvestmentController>.value(
        value: controller!, // provides the controller to the widget tree
        child: const _InvestmentManagementView(), // the view that displays the
        //list of investments and allows user interactions
      );
    }

    // if no controller is provided, create a new instance of InvestmentController
    // and load the investments when the page is built, then provide it to the
    // widget tree using ChangeNotifierProvider, allowing the UI to react to
    // changes in the investment data and update accordingly when the controller's
    // state changes
    return ChangeNotifierProvider(
      create: (_) =>
          InvestmentController()..load(), // creates a new instance of
      // InvestmentController and calls the load method to fetch the investments when
      // the page is built, ensuring that the investment data is loaded and available for
      // display in the UI
      child: const _InvestmentManagementView(),
    );
  }
}

// The _InvestmentManagementView is a stateless widget that builds the UI for
// the investment management page. It displays a list of investments and allows
// the user to add, edit, or delete investments. It uses the InvestmentController
// to manage the state of the investments and perform actions such as loading,
// adding, editing, or deleting investments. The UI reacts to changes in the
// investment data and updates accordingly when the controller's state changes.
class _InvestmentManagementView extends StatelessWidget {
  const _InvestmentManagementView(); // constructor for the _InvestmentManagementView,
  // which is a private widget used internally by the InvestmentManagementPage to
  // build the UI for managing investments
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvestmentController>(); // watches the
    // InvestmentController for changes, allowing the UI to react to updates in
    // the investment data and state, such as loading status, errors, or changes

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
                                onPressed:
                                    inv.id == null || controller.isMutating
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
                                onPressed:
                                    inv.id == null || controller.isMutating
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
    // asks for explicit confirmation before deleting because this operation is
    // destructive and should not be triggered by accidental taps.
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

    // only proceed when the dialog returned true from the destructive action.
    if (confirmed != true) return;
    await controller.deleteInvestment(id);
  }

  Future<void> _openForm(
    BuildContext context, {
    required InvestmentController controller,
    Investment? existing,
  }) async {
    // pre-fills controllers when editing an existing record, otherwise starts
    // with empty inputs for a new investment entry.
    final assetController = TextEditingController(text: existing?.asset ?? '');
    final amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    // this modal returns true only after in-dialog validation succeeds.
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add investment' : 'Edit investment',
              ),
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

    // if the user cancels or dismisses the dialog, release controller resources
    // and skip repository mutations.
    if (shouldSave != true) {
      assetController.dispose();
      amountController.dispose();
      return;
    }

    // branch between create and update depending on whether an existing entity
    // was passed to the form helper.
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
