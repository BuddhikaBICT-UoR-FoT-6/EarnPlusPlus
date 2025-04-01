import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Production-grade animated fade-in widget with configurable delay and duration.
/// Perfect for sequential animations of list items or UI elements.
class AnimatedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const AnimatedFadeIn({
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    super.key,
  });

  @override
  State<AnimatedFadeIn> createState() => _AnimatedFadeInState();
}

class _AnimatedFadeInState extends State<AnimatedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Animated scale-up widget with bounce effect for attention-grabbing UI elements.
/// Ideal for buttons, cards, and important notifications.
class AnimatedScaleIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double begin;

  const AnimatedScaleIn({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.begin = 0.8,
    super.key,
  });

  @override
  State<AnimatedScaleIn> createState() => _AnimatedScaleInState();
}

class _AnimatedScaleInState extends State<AnimatedScaleIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scale = Tween<double>(
      begin: widget.begin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Animated slide-in widget with smooth directional entry.
/// Great for modal dialogs, drawers, and side panels.
class AnimatedSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Curve curve;

  const AnimatedSlideIn({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.begin = const Offset(1.0, 0.0),
    this.curve = Curves.easeOut,
    super.key,
  });

  @override
  State<AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<AnimatedSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _offset = Tween<Offset>(
      begin: widget.begin,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(position: _offset, child: widget.child);
  }
}

/// Production-grade animated card with elevation and transform effects on tap.
/// Combines fade-in, scale, and shadow animations for polished feel.
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final Duration delay;
  final EdgeInsets padding;
  final double elevation;

  const AnimatedCard({
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.padding = const EdgeInsets.all(0),
    this.elevation = 2.0,
    super.key,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            child: InkWell(
              onTap: widget.onTap,
              child: Card(elevation: widget.elevation, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated floating action button with smooth entrance animation.
class AnimatedFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Duration duration;

  const AnimatedFAB({
    required this.icon,
    required this.onPressed,
    this.tooltip = '',
    this.duration = const Duration(milliseconds: 600),
    super.key,
  });

  @override
  State<AnimatedFAB> createState() => _AnimatedFABState();
}

class _AnimatedFABState extends State<AnimatedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _rotation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: RotationTransition(
        turns: _rotation,
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          child: Icon(widget.icon),
        ),
      ),
    );
  }
}

/// Animated gradient background container useful for splash screens and headers.
class GradientContainer extends StatelessWidget {
  final LinearGradient gradient;
  final Widget? child;
  final BorderRadius borderRadius;

  const GradientContainer({
    required this.gradient,
    this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: borderRadius),
      child: child,
    );
  }
}

/// Shimmer loading animation for skeleton screens.
class ShimmerLoadingWidget extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerLoadingWidget({
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              colors: [
                AppColors.textMutedLight.withValues(alpha: 0.1),
                AppColors.textMutedLight.withValues(alpha: 0.3),
                AppColors.textMutedLight.withValues(alpha: 0.1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Animated gradient button with smooth hover and tap effects.
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final LinearGradient gradient;
  final Duration duration;
  final bool isLoading;

  const GradientButton({
    required this.text,
    required this.onPressed,
    this.gradient = AppColors.primaryGradient,
    this.duration = const Duration(milliseconds: 300),
    this.isLoading = false,
    super.key,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: widget.duration,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textLight,
                            ),
                          ),
                        )
                      : Text(
                          widget.text,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
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
