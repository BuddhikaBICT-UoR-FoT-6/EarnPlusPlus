import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/constants/app_strings.dart';
import 'package:my_app/core/utils/decimal_format.dart';
import 'package:my_app/core/widgets/animated_widgets.dart';
import 'package:my_app/features/investments/domain/investment.dart';
import 'package:my_app/features/investments/presentation/investment_controller.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/screens/admin_dashboard_page.dart';
import 'package:my_app/screens/investment_management_page.dart';
import 'package:my_app/screens/login_page.dart';
import 'package:my_app/screens/superadmin_dashboard_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
  }); // the DashboardPage class is a StatelessWidget
  // that represents the main dashboard screen of the application. It uses a
  // ChangeNotifierProvider to provide an instance of InvestmentController to the
  // widget tree, allowing the dashboard to manage and display investment data.
  // The build method returns a Scaffold with an AppBar, a Drawer for navigation,
  // and a body that displays various metrics and charts based on the state of the
  // InvestmentController, including loading indicators, error messages, and the list
  // of investments.

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // The ChangeNotifierProvider is used to provide an instance of InvestmentController
      // to the widget tree. This allows the dashboard to manage and display investment
      // data. The create method initializes the InvestmentController and calls its load
      // method to fetch the initial data. The child of the provider is the _DashboardView,
      // which is a separate widget that builds the actual UI of the dashboard based on the
      // state of the controller.
      create: (_) => InvestmentController()..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InvestmentController>(); // watches the
    // InvestmentController for changes, allowing the UI to react to updates in
    // the investment data and loading state. This enables the dashboard to display
    // the appropriate content based on whether the data is loading, has loaded
    // successfully, or if there was an error during fetching.

    // if the controller's state is unauthorized, it means the user's authentication
    // token is invalid or has expired. In this case, we schedule a post-frame callback
    // to log the user out and navigate them back to the LoginPage. This ensures that
    // the user is redirected to the login screen if they are not authorized to view
    // the dashboard, maintaining the security of the application by preventing access
    // to protected content when the authentication state is not valid.
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

    // the Scaffold widget provides the basic structure for the dashboard page,
    // including an AppBar with the title, a Drawer for navigation, and a body
    // that contains the main content of the dashboard. The body uses a Column to
    // layout various widgets that display metrics, charts, and lists based on the
    // state of the InvestmentController, allowing the dashboard to present investment
    // data in a user-friendly and organized manner. The Drawer includes navigation
    // options such as Dashboard, Settings, About, and Logout, providing easy access
    // to different parts of the application and allowing the user to manage their
    // session effectively.
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dashboardTitle)),
      drawer: Drawer(
        // The Drawer widget provides a navigation menu that slides in from the left side
        // of the screen. It contains a list of ListTile widgets that represent different
        // navigation options. When a user taps on one of these options, the corresponding
        // action is performed. For example, tapping on 'Dashboard' simply closes the drawer,
        // while tapping on 'Settings' shows a snackbar with a placeholder message. Tapping
        // on 'About' displays an about dialog with application information. Tapping on 'Logout'
        // triggers the logout process and navigates the user back to the LoginPage. This
        // provides a convenient way for users to navigate between different sections of the
        // application and manage their session.
        child: FutureBuilder<String>(
          future: AuthService().getCurrentRole(),
          builder: (context, snapshot) {
            final role = snapshot.data ?? 'user';
            final canOpenAdmin = role == 'admin' || role == 'superadmin';
            final canOpenSuperAdmin = role == 'superadmin';

            return ListView(
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
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Manage Investments'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InvestmentManagementPage(),
                      ),
                    );
                  },
                ),
                if (canOpenAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminDashboardPage(),
                        ),
                      );
                    },
                  ),
                if (canOpenSuperAdmin)
                  ListTile(
                    leading: const Icon(Icons.manage_accounts_outlined),
                    title: const Text('Superadmin Dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SuperAdminDashboardPage(),
                        ),
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
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.load();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // The Column widget is used to layout the child widgets vertically.
            // It contains a Row for the asset filter and refresh button, followed
            // by conditional widgets that display loading indicators, error messages,
            // metrics, charts, and lists based on the state of the InvestmentController.
            // This allows the dashboard to present investment data in an organized
            // and user-friendly manner, with different UI elements shown or hidden
            // depending on the current state of data loading and availability.
            Row(
              children: [
                const Text('Asset:'),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String>(
                  // The DropdownButton allows the user to select an asset for
                  // filtering the investments displayed on the dashboard. The
                  // value of the dropdown is bound to controller.selectedAsset,
                  // which reflects the currently selected asset. The items in the
                  // dropdown are generated from the list of assets provided by
                  // the controller.assets() method, creating a DropdownMenuItem
                  // for each asset. When the user selects a different asset from
                  // the dropdown, the onChanged callback is triggered, which calls
                  // controller.setAsset with the new value (or 'All' if the value is null)
                  // to update the selected asset and refresh the displayed
                  // investments accordingly.
                  value:
                      controller.selectedAsset, // the currently selected asset
                  // for filtering investments
                  items: controller
                      // the list of assets is obtained from the controller, which
                      // provides a method to retrieve the unique assets from the
                      // investments. This list is then mapped to a list of DropdownMenuItem
                      // widgets, where each item represents an asset that the user
                      // can select for filtering the displayed investments on the dashboard.
                      .assets()
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => controller.setAsset(v ?? 'All'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  // The ElevatedButton with an icon is used to trigger a refresh
                  // of the investment data.
                  onPressed: controller.load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(
              height: AppSpacing.lg,
            ), // appspacing.lg is used to add
            // vertical space between the asset filter row and the subsequent
            // content, improving the visual separation and layout of the dashboard.
            if (controller.state == InvestmentLoadState.loading)
              const _DashboardLoadingShimmer(),
            if (controller.state == InvestmentLoadState.error)
              _ErrorBanner(
                message: controller.error ?? 'Something went wrong',
                onRetry: controller.load,
              ),
            if (controller.state == InvestmentLoadState.empty)
              // If the state of the controller is empty, it means that
              // there are no investments to display. In this case, we show a message
              // to the user indicating that there are no investments available.
              // The message is centered on the screen
              const SizedBox(
                height: 220,
                child: Center(child: Text(AppStrings.emptyInvestments)),
              ),
            if (controller.state == InvestmentLoadState.success) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      delay: Duration.zero,
                      child: AnimatedKpiCard(
                        title: 'Total Invested',
                        value: controller.totalInvested.toDouble(),
                        fractionDigits: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 150),
                      child: AnimatedKpiCard(
                        title: 'Average',
                        value: controller.averageInvested.toDouble(),
                        fractionDigits: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 300),
                      child: AnimatedKpiCard(
                        title: 'Count',
                        value: controller.filtered.length.toDouble(),
                        fractionDigits: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _PortfolioInsightsPanel(investments: controller.filtered),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 420,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: AnimatedCard(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 200),
                        elevation: 4,
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
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  switchInCurve: Curves.easeOutCubic,
                                  switchOutCurve: Curves.easeInCubic,
                                  child: _SimpleLineChart(
                                    key: ValueKey(controller.filtered.length),
                                    investments: controller.filtered,
                                  ),
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
                      child: AnimatedCard(
                        duration: const Duration(milliseconds: 1000),
                        delay: const Duration(milliseconds: 400),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            children: [
                              const Text(
                                'Recent Investments',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: controller.filtered.length,
                                  itemBuilder: (context, i) {
                                    final inv = controller.filtered.reversed
                                        .toList()[i];
                                    return AnimatedFadeIn(
                                      duration: const Duration(
                                        milliseconds: 600,
                                      ),
                                      delay: Duration(milliseconds: i * 100),
                                      child: ListTile(
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

// the _ErrorBanner widget is a custom widget that displays an error message and
// a retry button. It is used in the dashboard to show error messages when there
// is an issue with loading the investment data. The widget takes a message and
// an onRetry callback as parameters. The message is displayed in a styled
// container with a background color that indicates an error, and the retry button
// allows the user to attempt to reload the data by calling the onRetry callback
// when pressed. This provides a user-friendly way to handle errors and allows
// users to easily recover from issues without needing to navigate away from the dashboard.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry; // the onRetry callback is a function that will be
  // called when the user presses the retry button. It is used to trigger a reload
  // of the investment data when an error occurs, allowing the user to attempt to
  // recover from the error

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  }); // the constructor
  // for the _ErrorBanner widget takes a message and an onRetry callback as required
  // parameters, ensuring that the widget is properly initialized with the necessary
  // information to display the error message and handle retry actions when an error
  // occurs in the dashboard.

  @override
  Widget build(BuildContext context) {
    // The build method of the _ErrorBanner widget constructs the UI for displaying
    // the error message and the retry button. It uses a Container with a background color
    // that indicates an error (using the errorContainer color from the theme) and
    // rounded corners for visual appeal. Inside the container, a Row is used to
    // layout the error message and the retry button horizontally. The error message
    // is displayed in a Text widget with a color that contrasts with the error
    // background (using onErrorContainer from the theme), and the retry button is
    // an ElevatedButton that calls the onRetry callback when pressed, allowing
    // the user to attempt to reload the data and recover from the error.
    return Container(
      width: double.infinity, // The width is set to double.infinity to make the
      // banner span the full width of its parent container, ensuring it is clearly
      // visible and prominent
      margin: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
      ), // adds vertical
      // spacing around the error banner, separating it from other content on the
      // dashboard and improving the overall layout and readability when an error
      // message is displayed.
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

class _PortfolioInsightsPanel extends StatelessWidget {
  final List<Investment> investments;

  const _PortfolioInsightsPanel({required this.investments});

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final startLast30 = now.subtract(const Duration(days: 30));
    final startPrev30 = now.subtract(const Duration(days: 60));

    final last30Total = investments
        .where((i) => i.date.isAfter(startLast30))
        .fold<double>(0, (sum, i) => sum + i.amount.toDouble());

    final prev30Total = investments
        .where((i) => i.date.isAfter(startPrev30) && i.date.isBefore(startLast30))
        .fold<double>(0, (sum, i) => sum + i.amount.toDouble());

    final monthlyGrowthPct = prev30Total <= 0
        ? (last30Total > 0 ? 100.0 : 0.0)
        : ((last30Total - prev30Total) / prev30Total) * 100;

    final trendLabel = monthlyGrowthPct > 3
        ? 'Uptrend'
        : monthlyGrowthPct < -3
            ? 'Downtrend'
            : 'Stable';

    final trendColor = monthlyGrowthPct > 3
        ? Colors.green
        : monthlyGrowthPct < -3
            ? Colors.red
            : Colors.blueGrey;

    final profitLossPct = monthlyGrowthPct * 0.65;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Portfolio Insights',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trendLabel,
                    style: TextStyle(color: trendColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _InsightMetricTile(
                    title: 'Profit / Loss',
                    value: '${profitLossPct >= 0 ? '+' : ''}${profitLossPct.toStringAsFixed(2)}%',
                    color: profitLossPct >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InsightMetricTile(
                    title: 'Monthly Snapshot',
                    value: '${monthlyGrowthPct >= 0 ? '+' : ''}${monthlyGrowthPct.toStringAsFixed(2)}%',
                    color: monthlyGrowthPct >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _AssetAllocationPie(investments: investments),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _MonthlyComparisonTile(
                      last30Total: last30Total,
                      prev30Total: prev30Total,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightMetricTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _InsightMetricTile({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _AssetAllocationPie extends StatelessWidget {
  final List<Investment> investments;

  const _AssetAllocationPie({required this.investments});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final inv in investments) {
      totals[inv.asset] = (totals[inv.asset] ?? 0) + inv.amount.toDouble();
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final palette = <Color>[
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.deepPurple,
      Colors.cyan,
    ];

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asset Allocation', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 26,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        color: palette[i % palette.length],
                        value: entries[i].value,
                        title: entries[i].key,
                        radius: 44,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyComparisonTile extends StatelessWidget {
  final double last30Total;
  final double prev30Total;

  const _MonthlyComparisonTile({required this.last30Total, required this.prev30Total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Performance', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text('Last 30d: ${last30Total.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          Text('Prev 30d: ${prev30Total.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (prev30Total <= 0 || last30Total <= 0)
                ? 1
                : (last30Total / (prev30Total + last30Total)).clamp(0.05, 1),
          ),
        ],
      ),
    );
  }
}

// Animated KPI card with count-up animation and improved styling.
class AnimatedKpiCard extends StatelessWidget {
  final String title;
  final double value;
  final int fractionDigits;

  const AnimatedKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.fractionDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AnimatedCount(
                value: value,
                fractionDigits: fractionDigits,
                textStyle: const TextStyle(
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

// Small widget that animates a numeric value from 0 to target using a Tween.
class AnimatedCount extends StatelessWidget {
  final double value;
  final int fractionDigits;
  final TextStyle? textStyle;

  const AnimatedCount({
    super.key,
    required this.value,
    this.fractionDigits = 2,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final text = val.toStringAsFixed(fractionDigits);
        return Text(text, style: textStyle);
      },
    );
  }
}

class _DashboardLoadingShimmer extends StatelessWidget {
  const _DashboardLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _ShimmerBlock(height: 4, radius: 2),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _ShimmerBlock(height: 84, radius: 12)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _ShimmerBlock(height: 84, radius: 12)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _ShimmerBlock(height: 84, radius: 12)),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _ShimmerBlock(height: 260, radius: 12),
      ],
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  final double height;
  final double radius;

  const _ShimmerBlock({required this.height, this.radius = 10});

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final start = Color.lerp(
          scheme.surfaceContainerHighest,
          scheme.surface,
          0.4 + (t * 0.2),
        );
        final end = Color.lerp(
          scheme.surfaceContainerHighest,
          scheme.surface,
          0.6 + (t * 0.2),
        );
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                start ?? scheme.surfaceContainerHighest,
                end ?? scheme.surface,
              ],
            ),
          ),
        );
      },
    );
  }
}

// the _SimpleLineChart widget is a custom widget that displays a line chart based
// on a list of investments. It uses the fl_chart package to create a line chart
// that visualizes the invested amount over time. The widget takes a list of
// Investment objects as input and generates a series of FlSpot points for the
// chart based on the amount of each investment.
class _SimpleLineChart extends StatelessWidget {
  final List<Investment> investments;

  const _SimpleLineChart({
    super.key,
    required this.investments,
  }); // the constructor for the
  // _SimpleLineChart widget takes a list of Investment objects as a required parameter,
  // ensuring that the widget is properly initialized with the necessary data to
  // generate the line chart based on the invested amounts over time.

  @override
  Widget build(BuildContext context) {
    if (investments.isEmpty) {
      return const Center(child: Text(AppStrings.emptyInvestments));
    }

    // the spots variable is created by mapping each investment to an FlSpot, which
    // represents a point on the line chart. The x value of each spot is the index
    // of the investment in the list (converted to double), and the y value is the
    // amount of the investment (also converted to double). This allows the line chart
    // to display the investments in the correct order and with the correct values.
    final spots = investments
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.amount.toDouble()))
        .toList();

    // the maxAmount variable is calculated by mapping the investments to their
    // amounts and using the reduce method to find the maximum amount.
    final maxAmount = investments
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1)
            .toDouble(), // the maxX value is set to the index
        // of the last spot, ensuring that the line chart scales correctly based
        // on the number of investments
        minY: 0,
        maxY: maxAmount <= 0 ? 1 : maxAmount * 1.2, // the maxY value is set to
        // 20% above the maximum amount to provide some padding at the top of the
        // chart, ensuring that the highest point is not too close to the edge of
        // the chart and improving the visual appearance of the graph.
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
