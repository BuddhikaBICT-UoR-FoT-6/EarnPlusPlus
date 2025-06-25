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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currentValue': currentValue,
        'plPercent': plPercent,
        'insightTags': insightTags,
      };
}

class InvestmentDetailDto {
  final int id;
  final String date;
  final String name;
  final double currentValue;

  InvestmentDetailDto({
    required this.id,
    required this.date,
    required this.name,
    required this.currentValue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'name': name,
        'currentValue': currentValue,
      };
}
