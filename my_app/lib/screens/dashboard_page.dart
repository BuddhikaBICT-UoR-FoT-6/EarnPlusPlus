import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class Investment {
  final DateTime date;
  final String asset;
  final double amount;

  Investment({required this.date, required this.asset, required this.amount});

  factory Investment.fromJson(Map<String, dynamic> json) => Investment(
    date: DateTime.parse(json['date'] as String),
    asset: json['asset'] as String,
    amount: (json['amount'] as num).toDouble(),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final String _baseUrl = 'http://10.0.2.2:8080';
  List<Investment> _allInvestments = [];
  String _selectedAsset = 'All';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchInvestments();
  }

  Future<void> _fetchInvestments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final resp = await http
          .get(
            Uri.parse('$_baseUrl/investments'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 401) {
        await AuthService().logout();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _allInvestments = list
              .map((e) => Investment.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned ${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch: $e';
        _loading = false;
      });
    }
  }

  List<Investment> get _filtered => _selectedAsset == 'All'
      ? _allInvestments
      : _allInvestments.where((i) => i.asset == _selectedAsset).toList();

  double get _totalInvested => _filtered.fold(0.0, (p, e) => p + e.amount);
  double get _averageInvested =>
      _filtered.isEmpty ? 0 : _totalInvested / _filtered.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Dashboard')),
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
                  applicationName: 'Investment Tracker',
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
                if (!context.mounted) {
                  return;
                }
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Asset:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedAsset,
                  items: _buildAssetItems(),
                  onChanged: (v) => setState(() => _selectedAsset = v ?? 'All'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _fetchInvestments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Row(
              children: [
                _MetricCard(
                  title: 'Total Invested',
                  value: _totalInvested.toStringAsFixed(0),
                ),
                const SizedBox(width: 8),
                _MetricCard(
                  title: 'Average',
                  value: _averageInvested.toStringAsFixed(1),
                ),
                const SizedBox(width: 8),
                _MetricCard(title: 'Count', value: _filtered.length.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Invested Over Time',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _SimpleLineChart(investments: _filtered),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text(
                              'Recent Rows',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final inv = _filtered.reversed.toList()[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${inv.asset} - ${inv.amount.toStringAsFixed(0)}',
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
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildAssetItems() {
    final assets = <String>{'All'};
    for (final inv in _allInvestments) {
      assets.add(inv.asset);
    }
    final sorted = assets.toList()..sort();
    return sorted
        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
        .toList();
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
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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
    if (investments.isEmpty) return const Center(child: Text('No data'));

    final spots = investments
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
        .toList();

    final maxY =
        investments.map((i) => i.amount).reduce((a, b) => a > b ? a : b) * 1.2;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
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
