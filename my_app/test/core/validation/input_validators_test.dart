import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/core/validation/input_validators.dart';

void main() {
  group('InputValidators.email', () {
    test('returns error for empty value', () {
      expect(InputValidators.email(''), 'Email is required');
    });

    test('returns null for valid value', () {
      expect(InputValidators.email('user@example.com'), isNull);
    });
  });

  group('InputValidators.password', () {
    test('returns error for short value', () {
      expect(
        InputValidators.password('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('returns null for valid password', () {
      expect(InputValidators.password('123456'), isNull);
    });
  });

  group('InputValidators.confirmPassword', () {
    test('returns mismatch error when values differ', () {
      expect(
        InputValidators.confirmPassword('a', 'b'),
        'Passwords do not match',
      );
    });

    test('returns null when values match', () {
      expect(InputValidators.confirmPassword('same', 'same'), isNull);
    });
  });
}
