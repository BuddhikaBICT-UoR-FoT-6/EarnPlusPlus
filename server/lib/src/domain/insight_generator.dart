abstract class InsightGenerator {
  /// Takes portfolio data and returns a list of generated insights.
  List<Map<String, String>> generate(List<Map<String, dynamic>> portfolio);
}

class RiskInsightGenerator implements InsightGenerator {
  @override
  List<Map<String, String>> generate(List<Map<String, dynamic>> portfolio) {
    if (portfolio.isEmpty) return [];
    return [
      {
        'tag': 'Concentration Risk',
        'description': 'Consider diversifying across more asset classes.'
      }
    ];
  }
}

class GrowthInsightGenerator implements InsightGenerator {
  @override
  List<Map<String, String>> generate(List<Map<String, dynamic>> portfolio) {
    if (portfolio.isEmpty) return [];
    return [
      {
        'tag': 'Steady Grower',
        'description': 'Your portfolio shows consistent long-term potential.'
      }
    ];
  }
}

class DiversificationInsightGenerator implements InsightGenerator {
  @override
  List<Map<String, String>> generate(List<Map<String, dynamic>> portfolio) {
    if (portfolio.isEmpty) return [];
    return [
      {
        'tag': 'Well Diversified',
        'description': 'Assets are balanced across multiple categories.'
      }
    ];
  }
}
