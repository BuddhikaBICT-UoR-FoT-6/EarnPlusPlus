import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/utils/decimal_format.dart';
import 'package:decimal/decimal.dart';

void main() {
  group('decimalToFixed', () {
    test('formats to two decimal places', () {
      final value = Decimal.parse('123.4');
      expect(decimalToFixed(value, fractionDigits: 2), '123.40');
    });

    test('supports zero fraction digits', () {
      final value = Decimal.parse('123.99');
      expect(decimalToFixed(value, fractionDigits: 0), '123');
    });
  });
}
