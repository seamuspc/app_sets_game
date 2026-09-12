import 'package:flutter/material.dart';

import '../../domain/player.dart';

/// A persistent leaderboard panel that slides up from the bottom of the
/// screen when toggled — unlike StandingOverlay (which auto-flashes
/// briefly on specific events), this stays open until the player
/// collapses it again via the chevron button. Uses the same individual
/// per-player card style as StandingOverlay, just laid out inside this
/// sliding panel instead of floating at the top of the screen.
class LeaderboardPanel extends StatelessWidget {
  const LeaderboardPanel({super.key, required this.players});

  /// Already sorted highest score first — see PlayersState.byRank.
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDCEEFF).withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: Color(0xFF90C2F2), width: 1),
          left: BorderSide(color: Color(0xFF90C2F2), width: 1),
          right: BorderSide(color: Color(0xFF90C2F2), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 56),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: players.asMap().entries.map((entry) {
                return _LeaderboardPlayerCard(
                  rank: entry.key + 1,
                  player: entry.value,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Same visual style as StandingOverlay's per-player card — a small
/// individual pale-blue card with a rank badge, name, and score.
class _LeaderboardPlayerCard extends StatelessWidget {
  const _LeaderboardPlayerCard({required this.rank, required this.player});

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
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF90C2F2), width: 1),
      ),
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
                decoration: TextDecoration.none,
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
