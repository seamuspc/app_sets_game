import 'player.dart';

/// A player's standing, used to drive the full-screen border color and
/// the flash overlay. Deliberately only these four — anything in the
/// middle of the pack (not leading, not last, didn't just lose the lead)
/// gets [neutral] and no border color.
enum PlayerStanding {
  /// Currently in sole first place.
  leading,

  /// Was in sole first place a moment ago, but another player just
  /// caught up or passed them. This is a one-shot transient status — see
  /// [computeStandings] for how long it should be shown before reverting
  /// to [neutral].
  justLostLead,

  /// Currently in sole last place (only meaningful with 3+ players — with
  /// 2 players, last place and "not leading" are the same thing, so this
  /// only fires separately once there's a real middle of the pack).
  last,

  /// Neither leading, last, nor just knocked off the top spot.
  neutral,
}

/// Result of a standings calculation: each player's current standing,
/// plus the new sole-leader id (or null if there's a tie for first) to
/// pass back in as [previousLeaderId] on the next score update — that's
/// what lets [justLostLead] be detected as an edge (a change), not a
/// static state.
class StandingsResult {
  const StandingsResult({
    required this.standings,
    required this.currentLeaderId,
  });

  final Map<String, PlayerStanding> standings;
  final String? currentLeaderId;
}

/// Computes each player's standing from their current scores.
///
/// [previousLeaderId] should be the `currentLeaderId` from the previous
/// call (null on the very first call) — it's what lets a player transition
/// through [PlayerStanding.justLostLead] for one update after losing sole
/// first place, rather than jumping straight to [PlayerStanding.neutral].
///
/// Ties are handled conservatively: a tie for first means nobody is
/// "leading" (both need sole possession to claim it), and a tie for last
/// means nobody is flagged "last" either — ties don't trigger either
/// extreme status, only neutral.
StandingsResult computeStandings(
  List<Player> players, {
  String? previousLeaderId,
}) {
  if (players.isEmpty) {
    return const StandingsResult(standings: {}, currentLeaderId: null);
  }

  final maxScore = players.map((p) => p.score).reduce((a, b) => a > b ? a : b);
  final minScore = players.map((p) => p.score).reduce((a, b) => a < b ? a : b);

  final leaders = players.where((p) => p.score == maxScore).toList();
  final trailers = players.where((p) => p.score == minScore).toList();

  // Sole leader only if exactly one player holds the top score, and (with
  // 2+ distinct scores in play) that top score is actually ahead of
  // someone — with only one player, or everyone tied, nobody "leads".
  final soleLeaderId =
      (leaders.length == 1 && maxScore != minScore) ? leaders.first.id : null;
  final soleLastId =
      (trailers.length == 1 && maxScore != minScore) ? trailers.first.id : null;

  final standings = <String, PlayerStanding>{};
  for (final player in players) {
    if (player.id == soleLeaderId) {
      standings[player.id] = PlayerStanding.leading;
    } else if (player.id == previousLeaderId && player.id != soleLeaderId) {
      // Was the sole leader last time, isn't anymore — the transient flag.
      standings[player.id] = PlayerStanding.justLostLead;
    } else if (player.id == soleLastId) {
      standings[player.id] = PlayerStanding.last;
    } else {
      standings[player.id] = PlayerStanding.neutral;
    }
  }

  return StandingsResult(standings: standings, currentLeaderId: soleLeaderId);
}
