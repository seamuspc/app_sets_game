import 'package:flutter/material.dart';

import '../../domain/player_standings.dart';

/// A full-screen colored border reflecting the local player's standing:
/// green while leading, orange for the moment right after losing the
/// lead, red while in last place, and no border otherwise. Wrap this
/// around a screen's content inside a Stack — it doesn't intercept touch
/// (IgnorePointer) and doesn't fill the screen with color, just outlines it.
class RankBorderOverlay extends StatelessWidget {
  const RankBorderOverlay({super.key, required this.standing});

  final PlayerStanding standing;

  Color? get _borderColor => switch (standing) {
        PlayerStanding.leading => Colors.green,
        PlayerStanding.justLostLead => Colors.orange,
        PlayerStanding.last => Colors.red,
        PlayerStanding.neutral => null,
      };

  @override
  Widget build(BuildContext context) {
    final color = _borderColor;
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          border: Border.all(
            color: color ?? Colors.transparent,
            width: 6,
          ),
        ),
      ),
    );
  }
}
