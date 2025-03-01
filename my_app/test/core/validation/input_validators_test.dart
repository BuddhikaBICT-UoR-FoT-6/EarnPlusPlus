import 'package:flutter_test/flutter_test.dart'; // imports the Flutter testing
// framework, which provides tools for writing unit tests
import 'package:my_app/core/validation/input_validators.dart'; // imports the

// InputValidators class that contains static methods for validating user input
void main() {
  // the test groups for the InputValidators class contain individual test cases
  // for validating email, password, and confirm password inputs. Each test case
  // checks for specific validation rules, such as ensuring that the email is not
  // empty and contains an '@' symbol, that the password is at least 6 characters
  // long, and that the confirm password matches the original password. These tests
  // help ensure that the input validation logic in the InputValidators class works as
  // expected and provides appropriate error messages for invalid input, improving the
  // overall quality and reliability of the app's authentication flow.
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
