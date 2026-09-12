import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/player.dart';

/// Translucent overlay: a message card ("You reached 4 sets!") on top,
/// then one frosted-glass card per player showing their rank and score.
/// Meant to flash on screen briefly (1-2s) rather than sit as persistent
/// UI — the parent screen controls WHEN this is visible and what
/// [message]/[badgeColor] to show (via a timer, see _flashStandingOverlay
/// in the game screen).
class StandingOverlay extends StatelessWidget {
  const StandingOverlay({
    super.key,
    required this.message,
    required this.badgeColor,
    required this.players,
  });

  final String message;
  final Color badgeColor;

  /// Already sorted highest score first — see PlayersState.byRank.
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isNotEmpty) ...[
                  _GlassPanel(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 9, color: badgeColor),
                        const SizedBox(width: 8),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: players.asMap().entries.map((entry) {
                    return _PlayerCard(rank: entry.key + 1, player: entry.value);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared frosted-glass panel style — light and translucent (not black),
/// used for both the message card and each player card.
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, this.width});

  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFDCEEFF).withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF90C2F2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.rank, required this.player});

  final int rank;
  final Player player;

  Color get _rankColor => switch (rank) {
        1 => const Color(0xFFB8860B),
        2 => const Color(0xFF6B7280),
        3 => const Color(0xFF92400E),
        _ => Colors.black38,
      };

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      width: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _rankColor, shape: BoxShape.circle),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.isLocal ? 'You' : player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: player.isLocal ? FontWeight.bold : FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${player.score}',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
