import 'package:decimal/decimal.dart'; // for handling decimal values

// Investment model represents a single investment entry with a date, asset name,
// and amount. It includes a factory constructor fromJson to create an Investment
// instance from a JSON map, parsing the date and amount appropriately.
// The amount is stored as a Decimal to maintain precision for financial calculations,
// and the date is parsed from an ISO8601 string format.
class Investment {
  final int? id;
  final DateTime date;
  final String asset;
  final Decimal amount;

  const Investment({
    this.id,
    required this.date,
    required this.asset,
    required this.amount,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    final rawAmount =
        json['amount']; // rawAmount can be a String or a num (int/double)
    // We use toString() to ensure we can parse it regardless depending on how
    // the backend sends it (as a string or a number), and then parse it into a
    // Decimal for precision.
    return Investment(
      id: (json['id'] as num?)?.toInt(),
      date: DateTime.parse(json['date'] as String),
      asset: json['asset'] as String,
      amount: Decimal.parse(rawAmount.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().split('T').first,
        'asset': asset,
        'amount': amount.toString(),
      };
}
