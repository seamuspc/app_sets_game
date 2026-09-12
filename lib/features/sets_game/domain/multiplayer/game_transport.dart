import 'game_message.dart';

/// A discovered game a client can try to join — found via whatever
/// discovery mechanism the transport uses (BLE scan results, a WiFi
/// local-network broadcast, an Internet lobby list).
class DiscoveredGame {
  const DiscoveredGame({
    required this.hostId,
    required this.hostName,
    required this.gameCode,
  });

  final String hostId;
  final String hostName;
  final String gameCode;
}

/// Connection state for the local device, whichever role it's playing.
enum TransportConnectionState {
  disconnected,
  hosting,
  discovering,
  connecting,
  connected,
}

/// The contract every transport (BLE now, WiFi/Internet later) must
/// implement. Nothing above this layer — the Lobby screen, the game
/// controller, the reconnect logic — needs to know or care which
/// transport is actually moving the bytes.
abstract class GameTransport {
  /// Current connection state, for UI to react to (e.g. show a spinner
  /// while `connecting`).
  Stream<TransportConnectionState> get connectionState;

  /// Every GameMessage received from the other side(s), already decoded.
  Stream<GameMessage> get incomingMessages;

  /// HOST SIDE: start advertising so nearby clients can discover and
  /// connect. Returns the game code players will see/enter.
  Future<String> startHosting({required String hostName});

  /// CLIENT SIDE: search for nearby hosts. Callers should listen to this
  /// stream and stop scanning (see [stopDiscovery]) once the player
  /// picks one, rather than scanning indefinitely.
  Stream<DiscoveredGame> discoverGames();

  Future<void> stopDiscovery();

  /// CLIENT SIDE: connect to a specific host found via [discoverGames].
  Future<void> connectToGame(DiscoveredGame game);

  /// Send a message to the host (if this device is a client) or
  /// broadcast to all connected clients (if this device is the host).
  Future<void> send(GameMessage message);

  /// Tears down the current connection(s) and stops hosting/discovering.
  Future<void> disconnect();
}
