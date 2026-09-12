import '../set_card.dart';

/// Every message that can be sent between the host and a client, over
/// whichever transport is active (BLE now; WiFi/Internet later — see
/// GameTransport). Deliberately transport-agnostic: this file has no
/// Bluetooth/socket imports at all, just plain data + JSON encoding.
///
/// The host is authoritative — see the class docs on each message for
/// which direction it flows.
sealed class GameMessage {
  const GameMessage();

  Map<String, dynamic> toJson();

  static GameMessage fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'claimAttempt' => ClaimAttempt.fromJson(json),
      'gameStateSnapshot' => GameStateSnapshot.fromJson(json),
      'cardsReplaced' => CardsReplaced.fromJson(json),
      'scoreUpdate' => ScoreUpdate.fromJson(json),
      'playerJoined' => PlayerJoined.fromJson(json),
      'playerLeft' => PlayerLeft.fromJson(json),
      'playerDisconnected' => PlayerDisconnected.fromJson(json),
      'playerReconnected' => PlayerReconnected.fromJson(json),
      'rejoinRequest' => RejoinRequest.fromJson(json),
      'heartbeat' => const Heartbeat(),
      _ => throw FormatException('Unknown GameMessage type: $type'),
    };
  }
}

/// CLIENT -> HOST. Sent the moment a player taps their 3rd card. The
/// host is the only one who decides whether this was valid — the client
/// never marks its own guess as correct.
class ClaimAttempt extends GameMessage {
  const ClaimAttempt({
    required this.playerId,
    required this.boardIndices,
    required this.clientTimestampMs,
  });

  final String playerId;
  final List<int> boardIndices;

  /// The client's own clock at the moment of the tap — used by the host
  /// to resolve near-simultaneous claims on overlapping cards as a draw
  /// (both players score) rather than picking a winner by network luck.
  final int clientTimestampMs;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'claimAttempt',
        'playerId': playerId,
        'boardIndices': boardIndices,
        'clientTimestampMs': clientTimestampMs,
      };

  factory ClaimAttempt.fromJson(Map<String, dynamic> json) => ClaimAttempt(
        playerId: json['playerId'] as String,
        boardIndices: (json['boardIndices'] as List).cast<int>(),
        clientTimestampMs: json['clientTimestampMs'] as int,
      );
}

/// HOST -> CLIENT(S). The full current game state, sent to a client
/// immediately on connect/rejoin so they start in sync, and optionally
/// as a periodic resync safety net.
class GameStateSnapshot extends GameMessage {
  const GameStateSnapshot({
    required this.board,
    required this.deckCount,
    required this.playerScores,
    required this.isGameOver,
  });

  final List<SetCard> board;

  /// Only the count, not the actual remaining cards — clients don't need
  /// (and shouldn't be able to infer) what's left in the deck.
  final int deckCount;

  /// playerId -> score.
  final Map<String, int> playerScores;
  final bool isGameOver;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gameStateSnapshot',
        'board': board.map(_cardToJson).toList(),
        'deckCount': deckCount,
        'playerScores': playerScores,
        'isGameOver': isGameOver,
      };

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) {
    return GameStateSnapshot(
      board: (json['board'] as List)
          .map((e) => _cardFromJson(e as Map<String, dynamic>))
          .toList(),
      deckCount: json['deckCount'] as int,
      playerScores: Map<String, int>.from(json['playerScores'] as Map),
      isGameOver: json['isGameOver'] as bool,
    );
  }
}

/// HOST -> ALL CLIENTS. Sent after resolving a valid claim (from any
/// player): which board positions changed and what's there now. Clients
/// apply this as a delta rather than waiting for a full snapshot, so
/// updates feel instant.
class CardsReplaced extends GameMessage {
  const CardsReplaced({
    required this.claimedByPlayerId,
    required this.replacedIndices,
    required this.newCards,
    required this.isDraw,
    required this.drawPlayerIds,
  });

  final String claimedByPlayerId;
  final List<int> replacedIndices;

  /// New cards for those indices — empty if the board shrank instead of
  /// refilling (deck ran out; see SetsGameController's existing logic).
  final List<SetCard> newCards;

  /// True when this claim was a near-simultaneous collision resolved as
  /// a draw — see [drawPlayerIds] for who all gets credit.
  final bool isDraw;
  final List<String> drawPlayerIds;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'cardsReplaced',
        'claimedByPlayerId': claimedByPlayerId,
        'replacedIndices': replacedIndices,
        'newCards': newCards.map(_cardToJson).toList(),
        'isDraw': isDraw,
        'drawPlayerIds': drawPlayerIds,
      };

  factory CardsReplaced.fromJson(Map<String, dynamic> json) => CardsReplaced(
        claimedByPlayerId: json['claimedByPlayerId'] as String,
        replacedIndices: (json['replacedIndices'] as List).cast<int>(),
        newCards: (json['newCards'] as List)
            .map((e) => _cardFromJson(e as Map<String, dynamic>))
            .toList(),
        isDraw: json['isDraw'] as bool,
        drawPlayerIds: (json['drawPlayerIds'] as List).cast<String>(),
      );
}

/// HOST -> ALL CLIENTS. A standalone score update — mainly for cases
/// that don't also involve a board change.
class ScoreUpdate extends GameMessage {
  const ScoreUpdate({required this.playerId, required this.newScore});

  final String playerId;
  final int newScore;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'scoreUpdate',
        'playerId': playerId,
        'newScore': newScore,
      };

  factory ScoreUpdate.fromJson(Map<String, dynamic> json) => ScoreUpdate(
        playerId: json['playerId'] as String,
        newScore: json['newScore'] as int,
      );
}

/// HOST -> ALL CLIENTS. A new player joined the lobby/game.
class PlayerJoined extends GameMessage {
  const PlayerJoined({required this.playerId, required this.playerName});

  final String playerId;
  final String playerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playerJoined',
        'playerId': playerId,
        'playerName': playerName,
      };

  factory PlayerJoined.fromJson(Map<String, dynamic> json) => PlayerJoined(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
      );
}

/// HOST -> ALL CLIENTS. A player was fully removed — either they left
/// deliberately, or their 2-minute reconnect grace period expired. This
/// is the permanent version; see [PlayerDisconnected] for the transient
/// "might come back" state.
class PlayerLeft extends GameMessage {
  const PlayerLeft({required this.playerId});

  final String playerId;

  @override
  Map<String, dynamic> toJson() => {'type': 'playerLeft', 'playerId': playerId};

  factory PlayerLeft.fromJson(Map<String, dynamic> json) =>
      PlayerLeft(playerId: json['playerId'] as String);
}

/// HOST -> ALL CLIENTS. A player's connection dropped — they're not
/// removed yet, just flagged, while their 2-minute grace period runs.
/// Drives the "X left the game" flash overlay.
class PlayerDisconnected extends GameMessage {
  const PlayerDisconnected({required this.playerId, required this.playerName});

  final String playerId;
  final String playerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playerDisconnected',
        'playerId': playerId,
        'playerName': playerName,
      };

  factory PlayerDisconnected.fromJson(Map<String, dynamic> json) =>
      PlayerDisconnected(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
      );
}

/// HOST -> ALL CLIENTS. A previously-disconnected player reconnected
/// within their grace period. Drives the "X has rejoined" flash overlay.
class PlayerReconnected extends GameMessage {
  const PlayerReconnected({required this.playerId, required this.playerName});

  final String playerId;
  final String playerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'playerReconnected',
        'playerId': playerId,
        'playerName': playerName,
      };

  factory PlayerReconnected.fromJson(Map<String, dynamic> json) =>
      PlayerReconnected(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
      );
}

/// CLIENT -> HOST. Sent when reconnecting, carrying the player's stable
/// identity (their Firebase UID) so the host recognizes them as a
/// returning player rather than someone brand new.
class RejoinRequest extends GameMessage {
  const RejoinRequest({required this.playerId, required this.playerName});

  final String playerId;
  final String playerName;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rejoinRequest',
        'playerId': playerId,
        'playerName': playerName,
      };

  factory RejoinRequest.fromJson(Map<String, dynamic> json) => RejoinRequest(
        playerId: json['playerId'] as String,
        playerName: json['playerName'] as String,
      );
}

/// BOTH DIRECTIONS. A liveness ping — used to detect a dropped
/// connection before the transport itself notices (BLE in particular
/// can take a while to report a lost link).
class Heartbeat extends GameMessage {
  const Heartbeat();

  @override
  Map<String, dynamic> toJson() => {'type': 'heartbeat'};
}

Map<String, dynamic> _cardToJson(SetCard card) => {
      'color': card.color.name,
      'shape': card.shape.name,
      'shading': card.shading.name,
      'count': card.count,
    };

SetCard _cardFromJson(Map<String, dynamic> json) => SetCard(
      color: CardColor.values.byName(json['color'] as String),
      shape: CardShape.values.byName(json['shape'] as String),
      shading: CardShading.values.byName(json['shading'] as String),
      count: json['count'] as int,
    );
