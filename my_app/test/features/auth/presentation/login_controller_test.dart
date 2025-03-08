import 'dart:async'; // imports the dart:async library, which provides support
// for asynchronous programming in Dart, including Future and Completer classes
// used for handling asynchronous operations and testing asynchronous code in the
// login controller tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/features/auth/presentation/login_controller.dart';
import 'package:my_app/services/auth_service.dart';

// A fake implementation of the AuthService interface for testing purposes.
class _FakeAuthService extends AuthService {
  _FakeAuthService({
    this.shouldThrow = false,
    this.completer,
  }); // the constructor
  // allows for configuring the behavior of the fake service, such as whether it
  // should throw an exception during login and providing a Completer to control
  // the timing of asynchronous operations in tests.

  final bool
  shouldThrow; //  a boolean flag that determines whether the login method
  // should throw an exception
  final Completer<void>? completer; // an optional Completer that can be used to
  // control the timing of asynchronous

  // variables to store the last email and password used in the
  // login method, allowing tests to verify that the correct credentials were passed
  // to the login method.
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> login({required String email, required String password}) async {
    // simulates the login process. It stores the provided email and
    // password in the lastEmail and lastPassword variables for verification in
    // tests.
    lastEmail = email;
    lastPassword = password;

    // If a Completer is provided, it waits for the Completer's future to complete
    // before proceeding, allowing tests to control the timing of the login process.
    // What completer does is it allows the test to pause the execution of the login
    // method until the test decides to complete the future, which is useful for
    // testing the isSubmitting state of the LoginController during the login process,
    // ensuring that the controller correctly updates its state and notifies listeners
    // while the login operation is in progress. By using a Completer, tests can
    // simulate the asynchronous nature of the login process and verify that the
    // LoginController behaves correctly during that time, such as showing a loading
    // indicator and preventing multiple login attempts until the first one is completed.
    if (completer != null) {
      await completer!.future;
    }

    // If the shouldThrow flag is set to true, it throws an exception to simulate
    // a login failure, allowing tests to verify that the LoginController handles
    // login failures correctly by setting the appropriate error message and returning
    // false. If shouldThrow is false, the login method completes successfully,
    // simulating a successful login.
    if (shouldThrow) {
      throw Exception('invalid credentials');
    }
  }
}

void main() {
  test('login success returns true and clears error', () async {
    // the test verifies that a successful login returns true, sets isSubmitting
    // to false, and clears any error message.
    final fake = _FakeAuthService();
    final controller = LoginController(authService: fake);

    final result = await controller.login(
      email: 'user@example.com',
      password: 'secret123',
    );

    expect(
      result,
      isTrue,
    ); // verifies that the login method returns true on success
    expect(
      controller.isSubmitting,
      isFalse,
    ); // verifies that isSubmitting is set
    // to false after the login process completes
    expect(
      controller.error,
      isNull,
    ); // verifies that the error message is cleared
    // after a successful login
    expect(fake.lastEmail, 'user@example.com'); // verifies that the last email
    // passed to the login method is correct
    expect(fake.lastPassword, 'secret123'); // verifies that the last password
    // passed to the login method is correct
  });

  test('login failure returns false and sets error message', () async {
    // the test verifies that a failed login returns false, sets isSubmitting to false,
    // and sets an appropriate error message.
    final controller = LoginController(
      authService: _FakeAuthService(shouldThrow: true),
    );

    final result = await controller.login(
      email: 'user@example.com',
      password: 'wrong',
    );

    expect(result, isFalse);
    expect(controller.isSubmitting, isFalse);
    expect(controller.error, contains('Login failed:'));
  });

  test('notifies listeners on start and finish', () async {
    // the test verifies that the controller notifies its listeners when the login
    // process starts and finishes, ensuring that the UI can respond appropriately
    // to changes in the controller's state, such as showing a loading indicator
    // during the login process and updating the UI when the process is complete.

    final completer = Completer<void>(); // a Completer is used to control the
    // timing of the login process in this test, allowing the test to verify that
    // the controller correctly updates its state and notifies listeners while the
    // login operation is in progress. By using a Completer, the test can simulate
    // the asynchronous nature of the login process and ensure that the controller
    // behaves correctly during that time, such as showing a loading indicator and
    // preventing multiple login attempts until the first one is completed.
    final controller = LoginController(
      // the LoginController is initialized with a _FakeAuthService that uses the
      // completer to delay the completion of the login process, enabling the test to
      // verify the controller's behavior during the asynchronous operation.
      authService: _FakeAuthService(completer: completer),
    );

    //  a listener is added to the controller to count the number of times it
    // notifies its listeners, ensuring that the controller correctly notifies
    // its listeners when the login process starts and finishes. By counting the
    // notifications, the test verifies that the controller notifies its listeners
    // exactly twice: once when the login process starts (isSubmitting becomes true)
    // and once when it finishes (isSubmitting becomes false).
    int notifications = 0;
    controller.addListener(() {
      notifications++;
    });

    final future = controller.login(
      email: 'user@example.com',
      password: 'secret123',
    );

    // the test waits for a short duration to allow the login method to set isSubmitting
    // to true and notify listeners before the Completer is completed, ensuring that
    // the test can verify that the controller correctly updates its state and notifies
    // listeners while the login operation is in progress. By waiting for a short
    // duration, the test can check that the isSubmitting state is true and that
    // listeners have been notified at least once before the login process is completed,
    // providing confidence that the controller behaves correctly during the asynchronous
    // login operation.
    await Future<void>.delayed(Duration.zero);
    expect(controller.isSubmitting, isTrue);

    completer.complete();
    await future;

    expect(controller.isSubmitting, isFalse);
    expect(notifications, 2);
  });
}
