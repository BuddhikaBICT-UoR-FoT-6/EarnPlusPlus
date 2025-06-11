import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/investments/presentation/smart_insight_controller.dart';
import '../constants/app_spacing.dart';

class AskPortfolioCard extends StatefulWidget {
  const AskPortfolioCard({super.key});

  @override
  State<AskPortfolioCard> createState() => _AskPortfolioCardState();
}

class _AskPortfolioCardState extends State<AskPortfolioCard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late AnimationController _bgAnimationController;

  final List<String> _suggestedQueries = [
    'What is my top gainer?',
    'Is my portfolio diversified?',
    'Show risk analysis',
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _submitQuery(String query) {
    if (query.trim().isEmpty) return;
    context.read<SmartInsightController>().askPortfolio(query);
    _queryController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E3A8A).withValues(alpha: 0.6),
                              const Color(0xFF312E81).withValues(alpha: 0.6),
                              const Color(0xFF111827).withValues(alpha: 0.8),
                            ]
                          : [
                              const Color(0xFFDBEAFE).withValues(alpha: 0.8),
                              const Color(0xFFE0E7FF).withValues(alpha: 0.8),
                              const Color(0xFFF3F4F6).withValues(alpha: 0.9),
                            ],
                      stops: [
                        0.0,
                        _bgAnimationController.value * 0.5 + 0.5,
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Glassmorphism effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: isDark ? Colors.blueAccent : Colors.indigo,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ask Your Portfolio',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Get AI-powered insights about your investments instantly.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Search Box
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _queryController,
                    onSubmitted: _submitQuery,
                    decoration: InputDecoration(
                      hintText: 'E.g., Which asset is performing best?',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () => _submitQuery(_queryController.text),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Suggested Queries (Hick's Law - restrict choices)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedQueries.map((q) {
                    return ActionChip(
                      label: Text(
                        q,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _submitQuery(q),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                // Insights Result
                Consumer<SmartInsightController>(
                  builder: (context, insightCtrl, child) {
                    if (insightCtrl.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.md),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (insightCtrl.error != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          insightCtrl.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      );
                    }
                    if (insightCtrl.insights.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: insightCtrl.insights.map((insight) {
                                return Tooltip(
                                  message: insight['description'] ?? '',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6),
                                          Color(0xFF3B82F6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          insight['tag'] ?? 'Insight',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () {}, // TODO: handle feedback
                                          child: const Icon(
                                            Icons.thumb_up_alt_outlined,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () {}, // TODO: handle feedback
                                          child: const Icon(
                                            Icons.thumb_down_alt_outlined,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
