class GoalDto {
  final int id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String createdAt;

  GoalDto({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.createdAt,
  });

  factory GoalDto.fromJson(Map<String, dynamic> json) => GoalDto(
        id: json['id'] as int,
        title: json['title'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        createdAt: json['createdAt'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'createdAt': createdAt,
      };
}
