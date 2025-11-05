import 'package:flutter/material.dart';

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    final slideOffsetTween = Tween<Offset>(begin: const Offset(0.0, 0.02), end: Offset.zero);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: slideOffsetTween.animate(curved), child: child),
    );
  }
}
