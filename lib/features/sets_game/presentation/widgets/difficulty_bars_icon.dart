import 'package:flutter/material.dart';

import '../../domain/difficulty.dart';

/// A signal/battery-style icon: 3 vertical bars of increasing height,
/// filled up to [difficulty.barCount] and colored by level (green for
/// easy, orange for moderate, red for hard) — the same visual language
/// as a phone's signal-strength indicator.
class DifficultyBarsIcon extends StatelessWidget {
  const DifficultyBarsIcon({
    super.key,
    required this.difficulty,
    this.barWidth = 5,
    this.maxBarHeight = 16,
  });

  final GameDifficulty difficulty;
  final double barWidth;
  final double maxBarHeight;

  Color get _color => switch (difficulty) {
        GameDifficulty.easy => Colors.green,
        GameDifficulty.moderate => Colors.orange,
        GameDifficulty.hard => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    final filled = difficulty.barCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        final barNumber = i + 1;
        final height = maxBarHeight * (barNumber / 3);
        final isFilled = barNumber <= filled;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
          child: Container(
            width: barWidth,
            height: height,
            decoration: BoxDecoration(
              color: isFilled ? _color : _color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        );
      }),
    );
  }
}
