/// A player in a game session — the local device's player, or (once the
/// multiplayer layer exists) a remote peer synced over Bluetooth/WiFi/
/// Internet. Deliberately minimal for now; the networking layer will add
/// fields like connection state later without needing to touch this.
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.score,
    this.isLocal = false,
  });

  final String id;
  final String name;
  final int score;

  /// True for the player using this device — used to decide whose rank
  /// drives the screen border color, since every device shows its own
  /// player's standing, not a shared spectator view.
  final bool isLocal;

  Player copyWith({int? score}) => Player(
        id: id,
        name: name,
        score: score ?? this.score,
        isLocal: isLocal,
      );
}
