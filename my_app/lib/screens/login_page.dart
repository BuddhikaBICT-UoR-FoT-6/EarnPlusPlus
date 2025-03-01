import 'package:flutter/material.dart';
import '../core/validation/input_validators.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  }); // LoginPage is a stateful widget that represents
  // the login screen of the app. It contains a form for users to enter their
  // email and password, and handles the login process by communicating with the
  // AuthService to authenticate the user and navigate to the dashboard on success.

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey =
      GlobalKey<
        FormState
      >(); // a key to identify the form and validate its fields
  final _emailController = TextEditingController(); // controllers to manage the
  // text input for email and password fields
  final _passwordController = TextEditingController(); // a controller is used
  // to manage the state of the text field. It allows youto read the current value
  // of the text field and to listen for changes

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose(); // ensures that any additional cleanup in the parent class
    // is also performed when the widget is removed from the widget tree
  }

  // this function is called when the user submits the login form. It validates
  // the form fields, shows a loading state, and calls the AuthService to perform
  // the login. If the login is successful, it navigates to the DashboardPage.
  // If there is an error during login, it catches the exception and displays an
  // error message to the user. Finally, it resets the submitting state regardless
  // of success or failure.
  Future<void> _submit() async {
    FocusScope.of(
      context,
    ).unfocus(); // hides the keyboard when the user submits the form
    if (!_formKey.currentState!.validate()) {
      // if the form is not valid, it returns early and does not proceed with
      // the login process to avoid unnecessary API calls and to prompt the user
      // to correct the input errors
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // looks for the email and password entered by the user, trims any leading
      // or trailing whitespace, and calls the login method of the AuthService
      // to authenticate the user with the backend server
      await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // if the login is successful, it checks if the widget is still mounted
      //(i.e., the user has not navigated away from the login page) before navigating
      // to the DashboardPage. This is important to avoid trying to navigate from
      // a widget that is no longer in the widget tree, which could cause errors.
      if (!mounted) {
        return;
      }

      // If the widget is still mounted, it uses Navigator.pushReplacement to replace
      // the current login page with the dashboard page, effectively navigating
      // the user to the main screen of the app after a successful login.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Login failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // the build method defines the UI of the login page, including a gradient background,
  // a card containing the login form, and error messages if the login fails.
  // It uses Flutter's Material design components to create a visually appealing
  // and responsive login screen. The form includes fields for email and password,
  // with validation and a submit button that triggers the login process.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme; // retrieves the current color
    // scheme from the app's theme to use for styling the UI elements consistently
    // with the overall app design

    // the Scaffold widget provides the basic material design visual structure
    // for the login page, including the app bar, body, and other essential UI components.
    return Scaffold(
      body: Container(
        // The body of the scaffold contains a container with a gradient
        // background, centered content, and a scrollable card for the login form.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primaryContainer, colors.surface],
          ),
        ),
        child: Center(
          // the Center widget centers the content within the available space on the screen,
          // ensuring that the login form is prominently displayed in the middle of the page
          child: SingleChildScrollView(
            // the SingleChildScrollView allows the content to be scrollable if
            // it exceeds the available vertical space, which is especially useful
            // on smaller screens or when the keyboard is open
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 3, // the Card widget provides a material design card
                // with a slight elevation to create a sense of depth and separation
                // from the background, making the login form visually distinct
                // and easier to focus on for the user
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // the Column
                    // widget arranges its children vertically, and the
                    // crossAxisAlignment.stretch makes the children expand to
                    // fill the horizontal space of the card, creating a clean and
                    // organized layout for the login form and related UI elements
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
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: colors.onErrorContainer,
                            ), // the
                            // text color is set to onErrorContainer to ensure good
                            // contrast and readability against the errorContainer
                            // background color, following the Material Design
                            //guidelines for error states
                          ),
                        ),

                      // the Form widget contains the input fields for email and password,
                      // along with validation logic to ensure that the user enters
                      // valid credentials before attempting to log in. It uses
                      //TextFormField widgets for the input fields, which provide
                      // built-in support for validation and error messages.
                      //The form is wrapped in a Column to arrange the fields vertically,
                      // and it includes a submit button that triggers the login
                      // process when pressed.
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next, // sets the
                              // action button on the keyboard to "Next" to move to the next field
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator:
                                  InputValidators.email, // uses the email
                              // validator from the InputValidators class to validate
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done, // sets the
                              // action button on the keyboard to "Done" to submit the form
                              onFieldSubmitted: (_) => _isSubmitting
                                  ? null
                                  : _submit(), // allows the
                              // user to submit the form by pressing "Done"
                              // on the keyboard after entering the password,
                              // providing a convenient and intuitive way to
                              // log in without having to tap the submit button
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
                              validator:
                                  InputValidators.password, // uses the password
                              // validator from the InputValidators class to validate
                              // the password field includes a suffix icon button
                              //that toggles the obscureText property, allowing the
                              // user to show or hide the password they have
                              // entered for better usability
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        // the submit button is a FilledButton that triggers the
                        // _submit function when pressed. It shows a loading indicator
                        // when the login process is in progress, and it is disabled
                        // to prevent multiple submissions while the login request
                        // is being processed. The button's child changes based
                        //on the _isSubmitting state, showing either
                        //a CircularProgressIndicator or the "Login" text.
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
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
                        // the Row widget contains a "No account yet?" message and a "Register"
                        // button that navigates to the registration page when pressed.
                        // This provides a seamless way for new users to create an account
                        // if they don't already have one. The button is disabled during
                        // the login process to prevent accidental navigation.w3
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No account yet? '),
                          TextButton(
                            onPressed: _isSubmitting
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
