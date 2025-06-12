import 'package:flutter/material.dart';

import '../utils/investment_helpers.dart';

/// A widget that displays profit/loss information for an investment.
///
/// If profit/loss data is not available, it shows a placeholder.
/// Shows both dollar amount and percentage change.
class ProfitLossIndicator extends StatelessWidget {
  final double purchaseAmount;
  final double? currentAmount; // nullable - if not provided, shows "N/A"
  final bool compact; // if true, shows minimal version

  const ProfitLossIndicator({
    Key? key,
    required this.purchaseAmount,
    this.currentAmount,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentAmount == null) {
      return Text(
        'Performance: Not tracked',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
      );
    }

    final profitLoss = calculateProfitLoss(purchaseAmount, currentAmount!);
    final dollarChange = profitLoss['profit_loss']!;
    final percentChange = profitLoss['percent_change']!;

    final isGain = dollarChange >= 0;
    final textColor = isGain ? Colors.green : Colors.red;
    final icon = isGain ? Icons.trending_up : Icons.trending_down;

    if (compact) {
      return Row(
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '${formatProfitLoss(dollarChange)} (${formatPercentChange(percentChange)})',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGain
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Performance',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current Value: ${formatDollar(currentAmount!)}',
            style: TextStyle(color: textColor, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Profit/Loss: ${formatProfitLoss(dollarChange)}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Change: ${formatPercentChange(percentChange)}',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// A performance chart/diagram widget that shows profit/loss visually.
/// Displays a horizontal bar showing the percentage gain/loss.
class PerformanceBar extends StatelessWidget {
  final double purchaseAmount;
  final double? currentAmount;
  final String? title;

  const PerformanceBar({
    Key? key,
    required this.purchaseAmount,
    this.currentAmount,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (currentAmount == null) {
      return SizedBox.shrink();
    }

    final profitLoss = calculateProfitLoss(purchaseAmount, currentAmount!);
    final percentChange = profitLoss['percent_change']!;

    // Clamp percentage to -100% to 100% for visualization
    final clampedPercent = percentChange.clamp(-100, 100) / 100;
    final isGain = percentChange >= 0;
    final barColor = isGain ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(title!, style: Theme.of(context).textTheme.labelMedium),
        if (title != null) const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Background bar
                    Container(height: 24, color: Colors.grey.withOpacity(0.2)),
                    // Foreground bar (gain/loss)
                    if (isGain)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 24,
                          width:
                              MediaQuery.of(context).size.width *
                              clampedPercent.abs() *
                              0.5, // Adjust multiplier for visualization
                          color: barColor.withOpacity(0.7),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 24,
                          width:
                              MediaQuery.of(context).size.width *
                              clampedPercent.abs() *
                              0.5,
                          color: barColor.withOpacity(0.7),
                        ),
                      ),
                    // Neutral line (center)
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 24,
                        child: VerticalDivider(
                          color: Colors.grey.withOpacity(0.5),
                          thickness: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatPercentChange(percentChange),
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
