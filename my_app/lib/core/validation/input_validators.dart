// This file contains input validation functions for the application, such as
// validating email addresses, passwords, and other user inputs.
class InputValidators {
  // the email function takes a string input and checks if it is a valid email
  // address. It trims the input, checks if it is empty, and verifies that it
  //contains an '@' symbol.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Email is required';
    if (!v.contains('@')) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }
}
