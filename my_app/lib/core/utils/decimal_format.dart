import 'package:decimal/decimal.dart';

String decimalToFixed(Decimal value, {int fractionDigits = 2}) {
  final parts = value.toString().split('.');
  final whole = parts.first;
  final frac = parts.length > 1 ? parts[1] : '';

  if (fractionDigits <= 0) return whole;

  final normalized = (frac + ('0' * fractionDigits)).substring(0, fractionDigits);
  return '$whole.$normalized';
}
