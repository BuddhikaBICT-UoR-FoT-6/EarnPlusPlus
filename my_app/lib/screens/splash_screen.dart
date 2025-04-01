import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/widgets/animated_widgets.dart';

/// Production-grade animated splash screen with custom Earn++ logo animation,
/// smooth gradient background, and sequential element animations.
/// Displays during app initialization while checking authentication state.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoPulse;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Logo entrance and rotation animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(
      begin: -2.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    // Continuous pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _logoPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text fade-in and slide-up
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Start animations sequentially
    _logoController.forward().then((_) {
      _textController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientContainer(
        gradient: AppColors.primaryGradient,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo with rotation and scale
              ScaleTransition(
                scale: _logoScale,
                child: ScaleTransition(
                  scale: _logoPulse,
                  child: RotationTransition(
                    turns: _logoRotation,
                    child: _buildCustomLogo(),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // App name with fade-in
              FadeTransition(
                opacity: _textOpacity,
                child: Column(
                  children: [
                    Text(
                      'Earn++',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.textLight,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w800,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Investment Management',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textLight.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds custom Earn++ logo with gradient and layered design.
  /// Uses circular gradient container with elegant plus symbol.
  Widget _buildCustomLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.accentGreen.withOpacity(0.2),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated background circle
          CustomPaint(
            size: const Size(120, 120),
            painter: _LogoBackgroundPainter(),
          ),
          // Plus symbol with gradient
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.textLight.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add_circle_outline,
              size: 60,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated logo background patterns.
class _LogoBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer ring gradient
    final paintOuter = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.textLight.withValues(alpha: 0.3),
          AppColors.textLight.withValues(alpha: 0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paintOuter);

    // Inner decorative ring
    final paintInner = Paint()
      ..color = AppColors.textLight.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius * 0.75, paintInner);
  }

  @override
  bool shouldRepaint(_LogoBackgroundPainter oldDelegate) => false;
}
