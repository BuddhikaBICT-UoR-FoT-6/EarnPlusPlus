import 'package:flutter/material.dart'; // imports the Flutter material package,
// which provides a wide range of pre-built widgets and theming capabilities
// for building the user interface of the application using Material Design principles.
import 'package:provider/provider.dart'; // imports the Provider package, which is
// a popular state management solution in Flutter. It allows us to manage and provide
// state (like the RegisterController) to the widget tree efficiently, enabling
//widgets to listen for changes and rebuild when necessary without the need for
//complex state management patterns.

import '../core/validation/input_validators.dart'; // imports a custom InputValidators
// class that contains static methods for validating user input
import '../features/auth/presentation/register_controller.dart'; // imports the
// RegisterController class, which is responsible for handling the business logic
// of the registration process, such as managing form state, handling user input,
// and communicating with the authentication service to register a new user.
//This controller is used in the RegisterPage to manage the state of the registration
// form and provide feedback to the user during the registration process.

// The RegisterPage is a StatelessWidget that serves as the entry point for the
// registration screen. It uses a ChangeNotifierProvider to create and provide an
// instance of RegisterController to the widget tree, allowing child widgets to
// access the controller and listen for changes in the registration state.

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterController(),
      child: const _RegisterView(),
    );
  }
}

// The actual UI of the registration form is built in the _RegisterView, which is a
// StatefulWidget that manages the form state and user input for the registration
// process. The _RegisterView contains the form fields for email, password, and
// confirm password, as well as the logic for submitting the registration form and
// displaying error messages if registration fails.
class _RegisterView extends StatefulWidget {
  const _RegisterView(); // This consructor is used to create an instance of the
  // _RegisterView widget, which is the main content of the registration screen,
  // containing the form and logic for handling user input and registration submission.

  @override
  State<_RegisterView> createState() => _RegisterViewState(); // creates the mutable
  // state for the _RegisterView widget, allowing it to manage form state, user
  //input, and handle the registration process while providing feedback to the
  // user through the UI.
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey =
      GlobalKey<FormState>(); // a GlobalKey used to identify the form
  // and manage its state, allowing us to validate the form fields and control
  // the form submission process when the user attempts to register, ensuring that
  // the input is valid before
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // the dispose method is overridden to clean up the TextEditingControllers when
  // the widget is removed from the widget tree, preventing memory leaks and ensuring
  // that resources are properly released when the registration screen is no longer in use.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _otpController.dispose();
    super
        .dispose(); // calls the parent class's dispose method to ensure that any
    // additional cleanup in the widget lifecycle is also performed correctly.
  }

  // the _submit method is responsible for handling the form submission when the
  // user attempts to register. It first unfocuses any active text fields to dismiss
  // the keyboard, then validates the form using the form key. If the form is valid, it
  // calls the register method on the RegisterController with the email and password
  // from the text controllers. If registration is successful, it shows a success
  // message and navigates back to the previous screen.
  Future<void> _submit() async {
    FocusScope.of(
      context,
    ).unfocus(); // unfocuses any active text fields to dismiss
    // the keyboard when the user taps the submit button or tries to submit the form.
    if (!_formKey.currentState!.validate()) return; // validates the form fields
    // preventing the registration from proceeding if any fields are invalid or
    //missing. using the form key. If any of the validators fail, the form will
    //not submit and the user will be prompted to correct the input.

    final controller = context
        .read<RegisterController>(); // reads the RegisterController
    // to perform the registration from the context, allowing us to call the register
    // method with the provided email and password. The result of the registration
    // attempt is stored in the 'ok' variable, which is then used to determine
    // whether to show a success message or handle any errors that may have occurred
    // during the registration process.
    bool ok;
    if (controller.awaitingOtp) {
      ok = await controller.verifyOtp(otp: _otpController.text.trim());
    } else {
      ok = await controller.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return; // checks if the widget is still mounted in the widget
    // tree before attempting to show a SnackBar or navigate, ensuring that we
    // only perform these actions if the widget is still active and preventing
    // potential errors if the widget has been disposed of before the registration
    // response is received.

    // if the registration was successful (ok is true) and the widget is still
    // mounted, it shows a SnackBar with a success message and navigates back to
    // the previous screen, allowing the user to proceed to the login screen after
    // successfully creating an account. This provides feedback to the user that
    // their registration was successful.
    if (ok) {
      if (controller.awaitingOtp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'OTP sent to your email. Enter it to complete registration.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful. Please login.'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // the build method constructs the UI of the registration screen, including the
    // Scaffold, AppBar, and the form fields for email, password, and confirm password.

    final controller = context
        .watch<RegisterController>(); // watches the RegisterController
    // for changes, allowing the UI to react to changes in the registration state,
    // such as showing error messages or updating the submit button state based
    // on whether a registration attempt is in progress. By watching the controller,
    // the UI will automatically rebuild when the controller's state changes,
    // providing a responsive user experience during the registration process.
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // the Scaffold widget provides the basic structure for the registration screen,
      // including the app bar and body. The app bar contains the title "Create account",
      // and the body contains the registration form.
      appBar: AppBar(title: const Text('Create account')),
      body: Center(
        child: SingleChildScrollView(
          // the SingleChildScrollView allows the content to be scrollable if it
          // exceeds the available vertical space, ensuring that the form fields
          // and buttons are accessible on smaller screens or when the keyboard
          // is open, providing a better user experience across different device
          // sizes and orientations.
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, // sets the
                  // crossAxisAlignment to stretch, making the child widgets take
                  // up the full width of the column, ensuring that the form fields
                  // and buttons are aligned properly and provide a consistent
                  // layout for the registration
                  children: [
                    Text(
                      'Get started',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.awaitingOtp
                          ? 'Enter the OTP sent to your email to complete registration.'
                          : 'Create your account to start tracking your portfolio.',
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
                      // the Form widget is used to group the email, password,
                      // and confirm password text fields together, allowing us
                      // to manage their validation and submission together.
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            enabled: !controller.awaitingOtp,
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
                            textInputAction: TextInputAction.next,
                            enabled: !controller.awaitingOtp,
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            enabled: !controller.awaitingOtp,
                            onFieldSubmitted: (_) =>
                                controller.isSubmitting ? null : _submit(),
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
                            validator: (value) =>
                                InputValidators.confirmPassword(
                                  value,
                                  _passwordController.text,
                                ),
                          ),
                          if (controller.awaitingOtp) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) =>
                                  controller.isSubmitting ? null : _submit(),
                              decoration: const InputDecoration(
                                labelText: 'OTP',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                                helperText:
                                    'Enter the 6-digit code from your email',
                              ),
                              validator: (value) {
                                if (!controller.awaitingOtp) return null;
                                final v = (value ?? '').trim();
                                if (v.length < 4) {
                                  return 'Enter a valid OTP';
                                }
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      // the submit button that triggers the registration process
                      // when pressed. It shows a loading indicator while the
                      // registration is in progress and is disabled to prevent
                      // multiple clicks during the registration process by checking
                      // the isSubmitting state of the controller. The child of the
                      // button changes to a CircularProgressIndicator when the
                      // registration is being submitted, providing visual feedback
                      // to the user that their registration request is being processed.
                      height: 48,
                      child: FilledButton(
                        onPressed: controller.isSubmitting ? null : _submit,
                        child: controller.isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                controller.awaitingOtp
                                    ? 'Verify OTP'
                                    : 'Create account',
                              ),
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
