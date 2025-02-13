import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_spacing.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/decimal_format.dart';
import '../features/investments/domain/investment.dart';
import '../features/investments/presentation/investment_controller.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InvestmentController()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvestmentController>();

    if (controller.state == InvestmentLoadState.unauthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await AuthService().logout();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboardTitle)),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Menu')),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: AppStrings.appName,
                  applicationVersion: '0.1.0',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Asset:'),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String>(
                  value: controller.selectedAsset,
                  items: controller
                      .assets()
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => controller.setAsset(v ?? 'All'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (controller.state == InvestmentLoadState.loading)
              const LinearProgressIndicator(),
            if (controller.state == InvestmentLoadState.error)
              _ErrorBanner(
                message: controller.error ?? 'Something went wrong',
                onRetry: controller.load,
              ),
            if (controller.state == InvestmentLoadState.empty)
              const Expanded(
                child: Center(child: Text(AppStrings.emptyInvestments)),
              ),
            if (controller.state == InvestmentLoadState.success) ...[
              Row(
                children: [
                  _MetricCard(
                    title: 'Total Invested',
                    value: decimalToFixed(
                      controller.totalInvested,
                      fractionDigits: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                    title: 'Average',
                    value: decimalToFixed(
                      controller.averageInvested,
                      fractionDigits: 2,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _MetricCard(
                    title: 'Count',
                    value: controller.filtered.length.toString(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              const Text(
                                'Invested Over Time',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: _SimpleLineChart(
                                  investments: controller.filtered,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              const Text(
                                'Recent Rows',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: controller.filtered.length,
                                  itemBuilder: (context, i) {
                                    final inv =
                                        controller.filtered.reversed.toList()[i];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        '${inv.asset} - ${decimalToFixed(inv.amount, fractionDigits: 2)}',
                                      ),
                                      subtitle: Text(
                                        inv.date
                                            .toLocal()
                                            .toIso8601String()
                                            .split('T')
                                            .first,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.genericRetry),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;

  const _MetricCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  final List<Investment> investments;

  const _SimpleLineChart({required this.investments});

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const Center(child: Text(AppStrings.emptyInvestments));
    }

    final spots = investments
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.amount.toDouble()))
        .toList();

    final maxAmount = investments
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxAmount <= 0 ? 1 : maxAmount * 1.2,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            dotData: FlDotData(show: true),
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
          ),
        ],
      ),
    );
  }
}
