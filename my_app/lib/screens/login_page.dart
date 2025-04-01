import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/validation/input_validators.dart';
import 'package:my_app/core/widgets/animated_widgets.dart';
import 'package:my_app/features/auth/presentation/login_controller.dart';
import 'package:my_app/screens/dashboard_page.dart';
import 'package:my_app/screens/register_page.dart';

/// LoginPage serves as the entry point for user authentication.
/// Uses ChangeNotifierProvider for state management via LoginController
/// and displays beautiful animated UI with smooth transitions.
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

/// _LoginView implements the actual authentication UI and logic.
/// Manages form state, field validation, and handles login submission
/// with visual feedback and error handling. Includes animated cards,
/// gradient buttons, and smooth field transitions.
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<LoginController>();
    final ok = await controller.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return Scaffold(
      body: GradientContainer(
        gradient: AppColors.primaryGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // Animated logo or branding
                    AnimatedFadeIn(
                      duration: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: AppColors.textLight.withOpacity(0.9),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Earn++',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    color: AppColors.textLight,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Login form card with animation
                    AnimatedCard(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      elevation: 12,
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue managing your investments.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 24),
                            // Error message with smooth appearance
                            if (controller.error != null)
                              AnimatedFadeIn(
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          controller.error!,
                                          style: const TextStyle(
                                            color: AppColors.error,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Login form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email field with animation
                                  AnimatedFadeIn(
                                    duration: const Duration(milliseconds: 600),
                                    delay: const Duration(milliseconds: 300),
                                    child: TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      enabled: !controller.isSubmitting,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        hintText: 'Enter your email address',
                                        prefixIcon: const Icon(
                                          Icons.alternate_email,
                                        ),
                                      ),
                                      validator: InputValidators.email,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Password field with animation
                                  AnimatedFadeIn(
                                    duration: const Duration(milliseconds: 600),
                                    delay: const Duration(milliseconds: 400),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      enabled: !controller.isSubmitting,
                                      onFieldSubmitted: (_) =>
                                          controller.isSubmitting
                                          ? null
                                          : _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: 'Enter your password',
                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),
                                      validator: InputValidators.password,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Animated login button
                            AnimatedFadeIn(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 500),
                              child: GradientButton(
                                text: controller.isSubmitting
                                    ? 'Logging in...'
                                    : 'Login',
                                onPressed: controller.isSubmitting
                                    ? () {}
                                    : _submit,
                                isLoading: controller.isSubmitting,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Register link
                            AnimatedFadeIn(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 600),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'No account yet? ',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: controller.isSubmitting
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage(),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
