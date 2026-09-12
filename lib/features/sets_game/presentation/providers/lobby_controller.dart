import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/multiplayer/ble_game_transport.dart';
import '../../domain/multiplayer/game_message.dart';
import '../../domain/multiplayer/game_transport.dart';
import '../../domain/multiplayer/transport_mode.dart';
import '../../domain/multiplayer/wifi_game_transport.dart';
import 'lobby_state.dart';
import 'transport_mode_controller.dart';

class LobbyController extends Notifier<LobbyState> {
  GameTransport? _transport;

  @override
  LobbyState build() {
    ref.onDispose(() => _transport?.disconnect());
    return LobbyState.initial();
  }

  GameTransport _createTransport() {
    final mode = ref.read(transportModeControllerProvider);
    return switch (mode) {
      TransportMode.bluetooth => BleGameTransport(),
      TransportMode.wifi => WifiGameTransport(),
      TransportMode.internet => throw UnimplementedError(
          'Internet transport mode is not built yet.',
        ),
    };
  }

  Future<void> startHosting({
    required String localPlayerId,
    required String hostName,
  }) async {
    final transport = _createTransport();
    _transport = transport;

    transport.connectionState.listen((s) {
      state = state.copyWith(transportState: s);
    });
    transport.incomingMessages.listen(_onHostReceivedMessage);

    try {
      final code = await transport.startHosting(hostName: hostName);
      state = state.copyWith(
        role: LobbyRole.hosting,
        gameCode: code,
        players: [LobbyPlayer(id: localPlayerId, name: hostName)],
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not start hosting: $e');
    }
  }

  void _onHostReceivedMessage(GameMessage message) {
    // A client's initial handshake and a returning client's reconnect
    // both arrive as RejoinRequest — see the class doc on RejoinRequest
    // for why one message type covers both cases.
    if (message is RejoinRequest) {
      final alreadyKnown = state.players.any((p) => p.id == message.playerId);
      if (!alreadyKnown) {
        final updated = [
          ...state.players,
          LobbyPlayer(id: message.playerId, name: message.playerName),
        ];
        state = state.copyWith(players: updated);
      }
      // Broadcast the up-to-date roster so every connected client's
      // waiting-room list stays in sync, not just the host's.
      _transport?.send(
        PlayerJoined(playerId: message.playerId, playerName: message.playerName),
      );
    }
  }

  Future<void> startDiscovering() async {
    final transport = _createTransport();
    _transport = transport;
    state = state.copyWith(role: LobbyRole.joining, discoveredGames: []);

    transport.connectionState.listen((s) {
      state = state.copyWith(transportState: s);
    });

    transport.discoverGames().listen((game) {
      final alreadyListed = state.discoveredGames.any((g) => g.hostId == game.hostId);
      if (!alreadyListed) {
        state = state.copyWith(discoveredGames: [...state.discoveredGames, game]);
      }
    });
  }

  Future<void> joinGame({
    required DiscoveredGame game,
    required String localPlayerId,
    required String localPlayerName,
  }) async {
    final transport = _transport;
    if (transport == null) return;

    transport.incomingMessages.listen(_onClientReceivedMessage);

    try {
      await transport.connectToGame(game);
      await transport.send(
        RejoinRequest(playerId: localPlayerId, playerName: localPlayerName),
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Could not join game: $e');
    }
  }

  void _onClientReceivedMessage(GameMessage message) {
    if (message is PlayerJoined) {
      final alreadyKnown = state.players.any((p) => p.id == message.playerId);
      if (!alreadyKnown) {
        state = state.copyWith(
          players: [
            ...state.players,
            LobbyPlayer(id: message.playerId, name: message.playerName),
          ],
        );
      }
    }
  }

  Future<void> leaveLobby() async {
    await _transport?.disconnect();
    _transport = null;
    state = LobbyState.initial();
  }

  /// Exposes the active transport so the (not-yet-built) real
  /// multiplayer game controller can hand it the same connection once
  /// "Start game" is pressed, instead of opening a new one.
  GameTransport? get activeTransport => _transport;
}

final lobbyControllerProvider =
    NotifierProvider<LobbyController, LobbyState>(LobbyController.new);
