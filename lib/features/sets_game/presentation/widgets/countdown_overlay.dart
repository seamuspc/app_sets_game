import 'dart:ui';

import 'package:flutter/material.dart';

/// A pale-blue, mostly-opaque card with a thin border, showing a large
/// countdown number during the pause after an opponent claims a set.
/// [count] should be 3, 2, or 1 — the parent screen controls timing and
/// hides this widget entirely (rather than passing 0) once the countdown
/// finishes. Styled to match StandingOverlay's cards.
class CountdownOverlay extends StatelessWidget {
  const CountdownOverlay({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(count),
          tween: Tween(begin: 0.6, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: 108,
                height: 108,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEEFF).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF90C2F2), width: 1),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 44,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
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
