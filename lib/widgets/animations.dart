import 'package:flutter/material.dart';

/// Widget ko neeche se fade + slide ke saath dikhata hai.
/// index se delay milta hai, to list ek ke baad ek aati hai.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 80).clamp(0, 800);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 450 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 22),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
