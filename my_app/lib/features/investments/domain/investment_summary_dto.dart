class InvestmentSummaryDto {
  final int id;
  final String name;
  final double currentValue;
  final double plPercent;
  final List<String> insightTags;

  InvestmentSummaryDto({
    required this.id,
    required this.name,
    required this.currentValue,
    required this.plPercent,
    required this.insightTags,
  });

  factory InvestmentSummaryDto.fromJson(Map<String, dynamic> json) {
    return InvestmentSummaryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
      plPercent: (json['plPercent'] as num).toDouble(),
      insightTags: (json['insightTags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
