import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/player.dart';
import '../../domain/player_standings.dart';

const localPlayerId = 'local-player';
const maxPlayers = 10;

/// Set to false once the real multiplayer layer exists — this is purely
/// so the border-color/standing-overlay UI can be seen and tested on one
/// device before there's a network to supply real opponents. Has no
/// effect outside debug builds (see kDebugMode check below), so it can
/// never accidentally ship.
const simulateBotPlayersInDebug = true;

class PlayersState {
  const PlayersState({
    required this.players,
    required this.standings,
    required this.currentLeaderId,
  });

  final List<Player> players;
  final Map<String, PlayerStanding> standings;
  final String? currentLeaderId;

  factory PlayersState.initial() {
    const local = Player(id: localPlayerId, name: 'You', score: 0, isLocal: true);
    final players = [
      local,
      if (kDebugMode && simulateBotPlayersInDebug) ..._debugBots,
    ];
    final result = computeStandings(players);
    return PlayersState(
      players: players,
      standings: result.standings,
      currentLeaderId: result.currentLeaderId,
    );
  }

  static const _debugBots = [
    Player(id: 'bot-1', name: 'Bot Alex', score: 0),
    Player(id: 'bot-2', name: 'Bot Sam', score: 0),
  ];

  PlayerStanding standingFor(String playerId) =>
      standings[playerId] ?? PlayerStanding.neutral;

  /// Players sorted highest score first, for the leaderboard overlay.
  List<Player> get byRank =>
      [...players]..sort((a, b) => b.score.compareTo(a.score));
}

class PlayersController extends Notifier<PlayersState> {
  @override
  PlayersState build() => PlayersState.initial();

  void incrementScore(String playerId) {
    final updated = state.players
        .map((p) => p.id == playerId ? p.copyWith(score: p.score + 1) : p)
        .toList();
    final result =
        computeStandings(updated, previousLeaderId: state.currentLeaderId);
    state = PlayersState(
      players: updated,
      standings: result.standings,
      currentLeaderId: result.currentLeaderId,
    );
  }

  void reset() {
    state = PlayersState.initial();
  }
}

final playersControllerProvider =
    NotifierProvider<PlayersController, PlayersState>(PlayersController.new);
