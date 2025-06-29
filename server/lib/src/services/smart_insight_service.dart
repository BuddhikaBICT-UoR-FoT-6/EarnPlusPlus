import '../domain/insight_generator.dart';

class SmartInsightService {
  final List<InsightGenerator> _generators;

  SmartInsightService(this._generators);

  List<Map<String, String>> analyzePortfolio(List<Map<String, dynamic>> portfolio) {
    final List<Map<String, String>> allInsights = [];
    for (final generator in _generators) {
      allInsights.addAll(generator.generate(portfolio));
    }
    // Limit to max 3 tags per Miller's Law (from Phase 8)
    return allInsights.take(3).toList();
  }
}
