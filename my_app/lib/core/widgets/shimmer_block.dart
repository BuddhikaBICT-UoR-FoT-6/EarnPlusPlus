import 'package:flutter/material.dart';

class ShimmerBlock extends StatefulWidget {
  final double height;
  final double radius;
  final double? width;

  const ShimmerBlock({
    super.key,
    required this.height,
    this.radius = 10,
    this.width,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            color: Color.lerp(
              scheme.surfaceContainerHighest,
              scheme.surfaceContainer,
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}
