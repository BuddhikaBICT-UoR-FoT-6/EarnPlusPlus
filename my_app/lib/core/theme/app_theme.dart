import 'package:flutter/material.dart'; // importing the Flutter material package
// to use Material Design components and theming features

// The AppTheme class defines the visual styling for the application, including
// colors, typography, and input decoration themes
class AppTheme {
  // returns a ThemeData object configured with a light color scheme
  // and custom input decoration styles. It uses a seed color to generate the color
  // scheme and applies Material 3 design principles. The input decoration theme
  // is customized to have filled backgrounds and rounded borders for input fields,
  // providing a consistent and modern look across the app's user interface.
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    );

    return base.copyWith(
      // the copyWith method is used to create a new ThemeData object based on
      // the base theme, allowing us to override specific properties like the
      // inputDecorationTheme without affecting the rest of the theme's configuration.
      // This approach promotes code reuse and makes it easier to maintain a
      // consistent theme across the app
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
