import 'package:flutter_test/flutter_test.dart'; // adds Flutter's testing framework
// for writing unit and widget tests
import 'package:my_app/core/utils/decimal_format.dart'; // imports the decimal
// formatting utility function that formats Decimal values to a fixed number of
// decimal places, ensuring consistent display of financial data throughout the app
import 'package:decimal/decimal.dart'; // for handling decimal values with high precision,
// especially important for financial calculations to avoid issues with floating-point
// representation

void main() {
  // the test group for the decimalToFixed function contains two test cases to
  // verify that the function correctly formats Decimal values to a specified
  // number of decimal places and handles cases where zero fraction digits are requested,
  // ensuring that the function behaves as expected in different scenarios and
  // provides accurate formatting for financial data.
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
