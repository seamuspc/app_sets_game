import '../../domain/multiplayer/game_transport.dart';

enum LobbyRole { none, hosting, joining }

class LobbyPlayer {
  const LobbyPlayer({required this.id, required this.name});
  final String id;
  final String name;
}

class LobbyState {
  const LobbyState({
    required this.role,
    required this.gameCode,
    required this.players,
    required this.discoveredGames,
    required this.transportState,
    required this.errorMessage,
  });

  factory LobbyState.initial() => const LobbyState(
        role: LobbyRole.none,
        gameCode: null,
        players: [],
        discoveredGames: [],
        transportState: TransportConnectionState.disconnected,
        errorMessage: '',
      );

  final LobbyRole role;
  final String? gameCode;

  /// Everyone currently in the lobby, host included — this is what the
  /// waiting-room list on the Host tab renders.
  final List<LobbyPlayer> players;

  /// Nearby games found so far — what the Join tab's list renders.
  final List<DiscoveredGame> discoveredGames;

  final TransportConnectionState transportState;

  /// Empty string means no error — see the note on GameState for why
  /// this file avoids a nullable field here (copyWith can't distinguish
  /// "leave unchanged" from "explicitly clear to null" with the `??`
  /// pattern used everywhere else in this codebase).
  final String errorMessage;

  LobbyState copyWith({
    LobbyRole? role,
    String? gameCode,
    List<LobbyPlayer>? players,
    List<DiscoveredGame>? discoveredGames,
    TransportConnectionState? transportState,
    String? errorMessage,
  }) {
    return LobbyState(
      role: role ?? this.role,
      gameCode: gameCode ?? this.gameCode,
      players: players ?? this.players,
      discoveredGames: discoveredGames ?? this.discoveredGames,
      transportState: transportState ?? this.transportState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
