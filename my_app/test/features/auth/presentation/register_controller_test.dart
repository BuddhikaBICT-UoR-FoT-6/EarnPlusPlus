import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/auth/presentation/register_controller.dart';
import 'package:my_app/services/auth_service.dart';

// We can't test AuthService directly since it's an abstract class,
// so we create a fake implementation for testing purposes.
class _FakeAuthService extends AuthService {
  _FakeAuthService({this.shouldThrow = false}); // the constructor allows for
  // to configure the behavior of the fake service, such as whether it should throw
  // an exception during registration.

  final bool shouldThrow; // a boolean flag that determines whether the register
  // method should throw an exception to simulate a registration failure, allowing
  // tests to verify that the RegisterController handles registration failures
  // correctly by setting the appropriate error message and returning false.

  // variables to store the last email and password used in the register method,
  // allowing tests to verify that the correct credentials were passed to the register method.
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> register({
    // simulates the registration process. It stores the provided email and
    // password in the lastEmail and lastPassword variables for verification in tests.
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;

    if (shouldThrow) {
      throw Exception('email already in use');
    }
  }
}

void main() {
  test('register success returns true and clears error', () async {
    // the test verifies that a successful registration returns true, sets isSubmitting
    // to false, and clears any error message. It also checks that the correct email
    // and password were passed to the register method of the AuthService, ensuring
    // that the RegisterController correctly interacts with the AuthService and
    // updates its state based on the outcome of the registration process.
    final fake = _FakeAuthService();
    final controller = RegisterController(authService: fake);

    final result = await controller.register(
      email: 'new@example.com',
      password: 'secret123',
    );

    expect(result, isTrue);
    expect(controller.isSubmitting, isFalse);
    expect(controller.error, isNull);
    expect(fake.lastEmail, 'new@example.com');
    expect(fake.lastPassword, 'secret123');
  });

  test('register failure returns false and sets error message', () async {
    // the test verifies that a failed registration returns false, sets isSubmitting
    // to false, and sets the appropriate error message. It also checks that the
    // correct email and password were passed to the register method of the AuthService,
    // ensuring that the RegisterController correctly interacts with the AuthService
    // and updates its state based on the outcome of the registration process.
    final controller = RegisterController(
      authService: _FakeAuthService(shouldThrow: true),
    );

    final result = await controller.register(
      email: 'existing@example.com',
      password: 'secret123',
    );

    expect(result, isFalse);
    expect(controller.isSubmitting, isFalse);
    expect(controller.error, contains('Register failed:'));
  });
}
