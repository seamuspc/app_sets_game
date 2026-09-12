import 'dart:async';

import 'game_message.dart';
import 'game_transport.dart';

/// A GameTransport that connects two in-process instances directly,
/// with no real networking involved. This exists purely for tests and
/// local development — it lets the host-authoritative game logic
/// (collision resolution, reconnect handling, etc.) be fully exercised
/// without real Bluetooth hardware, which isn't available in CI or in
/// this sandbox. The real BLE implementation is a separate class behind
/// the same GameTransport interface — nothing above this layer changes
/// when that's swapped in.
class InMemoryGameTransport implements GameTransport {
  InMemoryGameTransport({required this.localName});

  final String localName;

  final _connectionStateController =
      StreamController<TransportConnectionState>.broadcast();
  final _incomingController = StreamController<GameMessage>.broadcast();
  final _discoveredController = StreamController<DiscoveredGame>.broadcast();

  InMemoryGameTransport? _peer;
  String? _gameCode;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Stream<GameMessage> get incomingMessages => _incomingController.stream;

  @override
  Future<String> startHosting({required String hostName}) async {
    _gameCode = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
    _connectionStateController.add(TransportConnectionState.hosting);
    return _gameCode!;
  }

  @override
  Stream<DiscoveredGame> discoverGames() => _discoveredController.stream;

  @override
  Future<void> stopDiscovery() async {}

  /// TEST-ONLY helper: directly pair this transport with a hosting one,
  /// standing in for what a real BLE scan-and-connect would do.
  void pairWith(InMemoryGameTransport host) {
    _peer = host;
    host._peer = this;
    _connectionStateController.add(TransportConnectionState.connected);
    host._connectionStateController.add(TransportConnectionState.connected);
  }

  @override
  Future<void> connectToGame(DiscoveredGame game) async {
    _connectionStateController.add(TransportConnectionState.connecting);
    // Real implementation resolves `game.hostId` to an actual BLE/WiFi
    // peer here; tests use pairWith() directly instead.
  }

  @override
  Future<void> send(GameMessage message) async {
    _peer?._incomingController.add(message);
  }

  @override
  Future<void> disconnect() async {
    _peer?._peer = null;
    _peer = null;
    _connectionStateController.add(TransportConnectionState.disconnected);
  }

  void dispose() {
    _connectionStateController.close();
    _incomingController.close();
    _discoveredController.close();
  }
}
