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

  factory InvestmentDetailDto.fromJson(Map<String, dynamic> json) {
    return InvestmentDetailDto(
      id: json['id'] as int,
      date: json['date'] as String,
      name: json['name'] as String,
      currentValue: (json['currentValue'] as num).toDouble(),
    );
  }
}
