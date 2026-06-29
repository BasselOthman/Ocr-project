import 'package:flutter/material.dart';

class AnimatedScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double scaleDownTo;
  final Duration duration;

  const AnimatedScaleButton({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleDownTo = 0.98,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleDownTo : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
