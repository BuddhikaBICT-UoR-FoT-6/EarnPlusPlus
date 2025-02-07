import 'package:decimal/decimal.dart';

class Investment {
  final DateTime date;
  final String asset;
  final Decimal amount;

  const Investment({
    required this.date,
    required this.asset,
    required this.amount,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return Investment(
      date: DateTime.parse(json['date'] as String),
      asset: json['asset'] as String,
      amount: Decimal.parse(rawAmount.toString()),
    );
  }
}
