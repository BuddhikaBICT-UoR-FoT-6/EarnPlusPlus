import 'package:flutter/material.dart';

import '../utils/investment_helpers.dart';
import '../widgets/profit_loss_widgets.dart';
import '../../features/investments/domain/investment_summary_dto.dart';

/// A detailed investment card that shows investment information with optional
/// profit/loss tracking and performance visualization.
class InvestmentDetailCard extends StatefulWidget {
  final InvestmentSummaryDto investment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final double?
  currentValue; // Optional: current market value for P/L calculation

  const InvestmentDetailCard({
    super.key,
    required this.investment,
    this.onEdit,
    this.onDelete,
    this.currentValue,
  });

  @override
  State<InvestmentDetailCard> createState() => _InvestmentDetailCardState();
}

class _InvestmentDetailCardState extends State<InvestmentDetailCard> {
  bool _isExpanded = false;
  double? _tempCurrentValue; // Temporary current value for calculation

  /// Opens a dialog to input the current market value for profit/loss calculation
  Future<void> _showCurrentValueDialog() async {
    final currentValueController = TextEditingController(
      text: _tempCurrentValue?.toStringAsFixed(2) ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Calculate Profit/Loss'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Asset: ${widget.investment.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Purchase Amount: ${formatDollar(widget.investment.currentValue)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentValueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Current Value (\$)',
                helperText: 'Enter the current market value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(currentValueController.text.trim());
              if (value != null && value > 0) {
                setState(() => _tempCurrentValue = value);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Calculate'),
          ),
        ],
      ),
    );

    currentValueController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.investment.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Amount: ${formatDollar(widget.investment.currentValue)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onEdit != null)
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline),
                    iconSize: 20,
                  ),
                IconButton(
                  tooltip: 'Details',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  iconSize: 20,
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investment Details',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Asset Symbol:',
                    value: widget.investment.name,
                  ),
                  _DetailRow(
                    label: 'Amount Invested:',
                    value: formatDollar(widget.investment.currentValue),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Performance Analysis',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: _showCurrentValueDialog,
                          icon: const Icon(Icons.calculate, size: 16),
                          label: Text(
                            _tempCurrentValue == null
                                ? 'Add Value'
                                : 'Update Value',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_tempCurrentValue != null) ...[
                    ProfitLossIndicator(
                      purchaseAmount: widget.investment.currentValue,
                      currentAmount: _tempCurrentValue,
                    ),
                    const SizedBox(height: 12),
                    PerformanceBar(
                      purchaseAmount: widget.investment.currentValue,
                      currentAmount: _tempCurrentValue,
                      title: 'Performance Bar:',
                    ),
                  ] else if (widget.currentValue != null) ...[
                    ProfitLossIndicator(
                      purchaseAmount: widget.investment.currentValue,
                      currentAmount: widget.currentValue,
                    ),
                    const SizedBox(height: 12),
                    PerformanceBar(
                      purchaseAmount: widget.investment.currentValue,
                      currentAmount: widget.currentValue,
                      title: 'Performance Bar:',
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enter the current market value above to calculate profit/loss.',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_tempCurrentValue != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            setState(() => _tempCurrentValue = null),
                        child: const Text('Clear Value'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A detail row widget that displays a label and value pair.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
