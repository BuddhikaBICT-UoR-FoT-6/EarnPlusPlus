import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validation/input_validators.dart';
import '../features/auth/presentation/login_controller.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

// The LoginPage widget is a StatelessWidget that serves as the entry point for
// user authentication. It uses a ChangeNotifierProvider to manage the state of
// the login process through the LoginController.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginController(),
      child: const _LoginView(),
    );
  }
}

// The _LoginView is a StatefulWidget that implements the actual UI and logic
// for the login form. It includes text fields for email and password, validation
// logic, and a submit button that triggers the login process. The UI also handles
// loading states and displays error messages if the login fails, providing a
// responsive and user-friendly experience for users trying to access their accounts.
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState(); //  the createState
  // method separation allows the UI to be built based on the current
  // state managed by _LoginViewState, ensuring that the UI updates correctly
  // in response to user interactions and asynchronous operations like login
  // requests. The _LoginViewState holds the form key, text controllers, and
  // password visibility state, making it easy to manage the form's behavior and
  // user inputs effectively. creates an instance of _LoginViewState, which manages
  // the state of the login form, including user input and form validation.
}

// The _LoginViewState class manages the state of the login form, including
// form key, text controllers, and password visibility. It handles user input,
// form validation, and the submission of login credentials to the LoginController.
// The build method constructs the UI based on the current state, displaying
// error messages, handling loading indicators, and providing a responsive
// interface for users to enter their credentials and submit the form.
class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>(); // a GlobalKey to manage the state of
  // the form and perform validation
  final _emailController =
      TextEditingController(); // a TextEditingController to
  // manage the input for the email field, allowing us to retrieve the email value
  // when the form is submitted
  final _passwordController =
      TextEditingController(); // a TextEditingController to
  // manage the input for the password field, allowing us to retrieve the password
  // value when the form is submitted
  bool _obscurePassword = true;

  // the dispose method is overridden to clean up the text controllers when the
  // widget is removed from the widget tree, preventing memory leaks and ensuring
  // that resources are properly released when the login page is no longer in use.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose(); // calls the superclass's dispose method to ensure that any
    // additional cleanup defined in the parent class is also performed
  }

  // The _submit method is responsible for handling the form submission. It first
  // dismisses the keyboard, then validates the form. If the form is valid, it
  // retrieves the LoginController from the context and calls its login method
  // with the email and password entered by the user. If the login is successful
  // and the widget is still mounted, it navigates to the DashboardPage. This method
  // ensures that the user's credentials are securely transmitted to the backend
  // for authentication. It also handles the UI state during the login process,
  // such as showing a loading indicator and displaying error messages if the
  // login fails, providing a smooth user experience.
  Future<void> _submit() async {
    FocusScope.of(
      context,
    ).unfocus(); // dismisses the keyboard by unfocusing any
    // focused input fields, ensuring that the user has a clear view of the login process
    if (!_formKey.currentState!.validate()) return; // validates the form using
    // the validate method of the FormState associated with the form key, and
    // if the validation fails, it returns early without attempting to log in,
    // allowing the user to correct their input before resubmitting

    final controller = context
        .read<LoginController>(); // retrieves the LoginController
    // from the context, which manages the state of the login process, allowing us
    // to call the login method with the user's credentials
    final ok = await controller.login(
      // calls the login method on the controller, passing the email and password
      // entered by the user. The email is trimmed to remove any leading or trailing
      // whitespace, ensuring that the credentials are clean before being sent to the
      // backend for authentication and the result of the login attempt is stored
      // in the "ok" variable, which will be true if the login was successful and
      // false otherwise
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // navigates to the DashboardPage if the login was successful and the widget
    // is still mounted in the widget tree, ensuring that the user is redirected
    // to the main application screen after a successful login, providing a seamless
    // transition from the login screen to the authenticated user interface of the
    // app. The check for "mounted" ensures that we only attempt to navigate if
    // the widget is still part of the widget tree, preventing potential errors if
    // the widget has been disposed of before the login response is received
    // if the login was successful (ok is true) and the widget is still mounted, it
    // navigates to the DashboardPage, allowing the user to access the main
    // functionality of the app after logging in successfully.
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // the build method constructs the UI for the login page, using a Scaffold with
    // a gradient background and a centered card containing the login form. It
    // displays error messages if the login fails, shows a loading indicator while
    // the login is in progress, and provides text fields for email and password
    // input, along with a submit button and a link to the registration page for
    // users who don't have an account yet. The UI is designed to be responsive and
    // user-friendly, guiding users through the login process with clear feedback and
    // intuitive navigation options.
    final controller = context
        .watch<LoginController>(); // watches the LoginController
    // for changes, allowing the UI to react to updates in the login state, such as
    // displaying error messages or updating the loading state of the submit button
    // retrieves the current color scheme from the theme, which is used to style the
    // UI elements consistently with the app's design, such as using error colors for
    // error messages and success colors for positive feedback, enhancing the
    // accessibility and visual appeal of the login form
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.surface],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    // the Column widget arranges the child widgets vertically,
                    // with crossAxisAlignment set to stretch to make the children
                    // take up the full width of the column, ensuring that the form
                    // fields and buttons are aligned properly and provide a consistent
                    // layout for the login form and related UI elements, creating
                    // a clean and organized interface for users to interact with when logging in
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to continue managing your investments.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      if (controller.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            controller.error!,
                            style: TextStyle(color: colors.onErrorContainer),
                          ),
                        ),
                      Form(
                        // the Form widget is used to group the email and password
                        // text fields together, allowing us to manage their validation
                        // and submission as a single unit. The form key is used to
                        // validate the form fields when the user attempts to submit
                        // the login form, ensuring that the input is correct before
                        // sending the login request to the backend.
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next, // sets the
                              // action button on the keyboard to "Next", allowing
                              // users to easily navigate to the next input field
                              // (password) after entering their email
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: InputValidators.email,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  controller.isSubmitting ? null : _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: InputValidators.password,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          // button that triggers the login process when pressed.
                          // It shows a loading indicator while the login is in
                          // progress and is disabled to prevent multiple clicks
                          // during the login process by checking the isSubmitting
                          // state of the controller. The child of the button changes
                          // to a CircularProgressIndicator when the login is being
                          // submitted, providing visual feedback to the user that
                          // their login request is being processed.
                          onPressed: controller.isSubmitting ? null : _submit,
                          child: controller.isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        // the Row widget arranges the child widgets horizontally,
                        // with mainAxisAlignment set to center to align the "No account yet?" text and
                        // "Register" button horizontally in the center of the row,
                        // creating a clear call-to-action for users who want to create
                        // a new account instead of logging in. The TextButton is
                        // disabled during the login process to prevent users from
                        // navigating away from the login screen while a login attempt
                        // is in progress, ensuring that the user experience remains
                        // consistent and prevents potential issues with concurrent
                        // operations.
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No account yet? '),
                          TextButton(
                            onPressed: controller.isSubmitting
                                ? null
                                : () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
