import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// provides a user interface for account creation
// handles form validation, UI feedback, and communication with the auth_service
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey =
      GlobalKey<
        FormState
      >(); // unique identifier for the form. it allows the code to reach into the form widget to trigger validation or save inputs
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSubmitting =
      false; // flag that tracks if a network request is in progress
  // when disabling the button and show a loading spinner
  bool _obscurePassword = true; // control password visibility
  bool _obscureConfirmPassword = true; // control confirm password visibility
  String? _error; // stores error messages from server

  // when the user leaves this page, these controllers are destroyed to free up the phone's memory.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // called when the user presses the submit button
  // 1. prevents multiple submissions
  // 2. validates the form inputs
  // 3. shows loading state
  // 4. calls the register method from AuthService
  // 5. displays success or error messages
  Future<void> _submit() async {
    FocusScope.of(
      context,
    ).unfocus(); // hides the keyboard when the user submits the form

    // triggers the validator functions on each form field. if any return a non-null string
    // the submission is halted and the error messages are shown to the user
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // sets the loading state and clears any previous error messages before making the network request
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // calls the register method from AuthService to send the registration data to the server.
      // if the server returns an error, it will throw an exception which is caught in the catch block below
      await AuthService().register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // if the widget is no longer in the widget tree
      // we don't want to call setState or show a snackbar,
      // so we check if it's still mounted before doing anything
      if (!mounted) {
        return;
      }

      // shows sucess message upon proper register
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful. Please login.')),
      );

      // return to previous page namely login
      Navigator.of(context).pop();
    } catch (e) {
      // if an error occurs (like email already in use, weak password, network error, etc),
      // the error message is caught and displayed to the user in a snackbar
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Register failed: $e';
      });
    } finally {
      // stop showing the loading spinner and re-enable the submit button
      // regardless of success or failure of the registration attempt
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // widget build method defines the UI of the registration page, including form
  // fields for email, password, and confirm password, as well as error messages
  // and a submit button with loading state feedback.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(
      context,
    ).colorScheme; // access the current theme's color scheme for consistent styling

    // the main scaffold of the page, which provides the app bar and body structure
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ), // simple app bar with the title of the page
      body: Center(
        child: SingleChildScrollView(
          // allows the content to be scrollable in case of smaller screens or when the keyboard is open
          padding: const EdgeInsets.all(
            20,
          ), // adds padding around the content for better aesthetics
          child: ConstrainedBox(
            // limits the maximum width of the form to 420
            // pixels for better readability on larger screens
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              // a material design card that contains the registration
              // form, giving it a distinct visual separation from the background
              elevation: 3, // adds a shadow to the card for depth
              child: Padding(
                // adds padding inside the card around the form content
                padding: const EdgeInsets.all(20),
                child: Column(
                  // arranges the child widgets vertically
                  crossAxisAlignment: CrossAxisAlignment
                      .stretch, // makes the children take the full width of the column
                  children: [
                    // the children of the column include text widgets
                    Text(
                      // title text at the top of the form
                      'Get started',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(
                      height: 6,
                    ), // small vertical space between the title and subtitle

                    Text(
                      // subtitle text that provides additional context to the user
                      'Create your account to start tracking your portfolio.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),

                    // if there is an error message to show, display it in a container with a red background
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ), // adds space below the error message
                        padding: const EdgeInsets.all(
                          12,
                        ), // adds padding inside the container around the error text
                        decoration: BoxDecoration(
                          // creates a colored container for the error message
                          color: colors.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          // text widget that displays the error message to the user
                          _error!,
                          style: TextStyle(color: colors.onErrorContainer),
                          // sets the text color to contrast with the error container background
                        ),
                      ),

                    // the registration form itself, which includes fields for
                    //email, password, and confirm password, along with validation logic for each field
                    Form(
                      key:
                          _formKey, // associates this form with the _formKey defined earlier for validation purposes
                      child: Column(
                        // arranges the form fields vertically
                        children: [
                          // the email input field, which includes validation to ensure the user enters a valid email address
                          TextFormField(
                            controller:
                                _emailController, // connects this text field to the _emailController to read the input value
                            keyboardType: TextInputType
                                .emailAddress, // shows the appropriate keyboard for email input on mobile devices
                            textInputAction: TextInputAction
                                .next, // changes the action button on the keyboard to "Next" to move to the next field
                            decoration: const InputDecoration(
                              // defines the appearance of the text field
                              labelText:
                                  'Email', // label that appears above the text field
                              prefixIcon: Icon(
                                Icons.alternate_email,
                              ), // icon that appears inside the text field to indicate it's for email input
                            ),
                            validator: (value) {
                              // validation logic for the email field,
                              // which checks if the input is not empty and contains an "@" symbol to ensure it's a valid email format
                              final v = (value ?? '').trim();
                              if (v.isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // the password input field, which includes validation
                          //to ensure the password is at least 6 characters long and is not empty
                          TextFormField(
                            controller:
                                _passwordController, // connects this text field to the _passwordController to read the input value
                            obscureText:
                                _obscurePassword, // hides the password input for security, controlled by the _obscurePassword boolean
                            textInputAction: TextInputAction
                                .next, // changes the action button on the keyboard to "Next" to move to the next field
                            decoration: InputDecoration(
                              // defines the appearance of the text field
                              labelText:
                                  'Password', // label that appears above the text field
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                              ), // icon that appears inside the text field
                              // to indicate it's for password input
                              suffixIcon: IconButton(
                                // icon button that allows the user to toggle password visibility
                                icon: Icon(
                                  // the icon changes based on whether the password is currently obscured or visible
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  // when the user presses this button,
                                  // it toggles the _obscurePassword boolean and calls setState to update the UI accordingly
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            // the confirm password field, which includes
                            // validation to ensure it matches the password field and is not empty
                            controller:
                                _confirmController, // connects this text field to the _confirmController to read the input value
                            obscureText:
                                _obscureConfirmPassword, // hides the input for security, controlled by the _obscureConfirmPassword boolean
                            textInputAction: TextInputAction
                                .done, // changes the action button on the keyboard
                            // to "Done" since this is the last field in the form
                            onFieldSubmitted: (_) => _isSubmitting
                                ? null
                                : _submit(), // allows the user to submit the form
                            // by pressing the "Done" button on the keyboard, but only if a submission is not already in progress
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              prefixIcon: const Icon(
                                Icons.lock_person_outlined,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      // constrains the height of the submit button and
                      // provides visual feedback when a submission is in progress by showing a loading spinner instead of the button text
                      height: 48,
                      child: FilledButton(
                        // the submit button, which calls the _submit method when pressed,
                        // but is disabled if a submission is already in progress
                        onPressed: _isSubmitting
                            ? null
                            : _submit, // disables the button
                        // when _isSubmitting is true to prevent multiple submissions
                        child:
                            _isSubmitting // shows a CircularProgressIndicator
                            // when a submission is in progress, otherwise it shows the text "Create account"
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Create account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
