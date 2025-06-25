import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../core/constants/app_spacing.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/animated_widgets.dart';
import '../services/auth_service.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService().getValidToken();
      final resp = await http.get(
        Uri.parse('${AppConfig.baseUrl}/leaderboard'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (resp.statusCode == 200) {
        setState(() {
          _leaderboard = jsonDecode(resp.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load leaderboard';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Investors'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _leaderboard.length,
                    itemBuilder: (context, index) {
                      final item = _leaderboard[index];
                      final isTop3 = index < 3;
                      final colors = [
                        const Color(0xFFFFD700), // Gold
                        const Color(0xFFC0C0C0), // Silver
                        const Color(0xFFCD7F32), // Bronze
                      ];

                      return AnimatedFadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        child: AnimatedSlideIn(
                          begin: const Offset(0.5, 0.0),
                          delay: Duration(milliseconds: 100 * index),
                          child: Card(
                            elevation: isTop3 ? 4 : 1,
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isTop3 ? colors[index] : Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: isTop3 ? Colors.black87 : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item['displayName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: Text(
                                '\$${item['score'].toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
