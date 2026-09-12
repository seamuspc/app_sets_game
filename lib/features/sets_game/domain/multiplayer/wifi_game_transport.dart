import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'game_message.dart';
import 'game_transport.dart';
import 'message_framer.dart';

const _dataPort = 51820;
const _discoveryPort = 51821;
const _discoveryPrefix = 'SETGAME|';

/// WiFi transport: a TCP connection carries the actual game messages
/// (host runs a ServerSocket, clients connect directly to its IP), and
/// UDP broadcast handles discovery on the local network, since a client
/// doesn't know the host's IP address ahead of time.
///
/// This uses only dart:io — no third-party plugin — so it's the most
/// reliable of the transport modes and, unlike Bluetooth, has no
/// foreground-only restriction. The real constraint: both devices must
/// be on the same local network (same WiFi, or one device's hotspot). It
/// does not work over the open internet — that's a separate transport
/// mode.
class WifiGameTransport implements GameTransport {
  final _connectionStateController =
      StreamController<TransportConnectionState>.broadcast();
  final _incomingController = StreamController<GameMessage>.broadcast();
  final _discoveredController = StreamController<DiscoveredGame>.broadcast();

  ServerSocket? _serverSocket;
  RawDatagramSocket? _discoverySocket;
  Timer? _advertiseTimer;
  StreamSubscription? _serverSub;
  StreamSubscription? _discoverySub;

  final Map<String, Socket> _clientSockets = {};
  final Map<String, GameMessageDecoder> _clientDecoders = {};

  Socket? _hostSocket;
  StreamSubscription? _hostSocketSub;
  final _hostDecoder = GameMessageDecoder();

  bool _isHost = false;

  @override
  Stream<TransportConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Stream<GameMessage> get incomingMessages => _incomingController.stream;

  @override
  Future<String> startHosting({required String hostName}) async {
    _isHost = true;
    final gameCode =
        (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();

    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _dataPort);
    _serverSub = _serverSocket!.listen(_onClientConnected);

    // Broadcast our presence periodically so clients scanning the local
    // network can find us without already knowing our IP address.
    _discoverySocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _discoverySocket!.broadcastEnabled = true;
    _advertiseTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final payload = utf8.encode('$_discoveryPrefix$hostName|$gameCode');
      _discoverySocket!
          .send(payload, InternetAddress('255.255.255.255'), _discoveryPort);
    });

    _connectionStateController.add(TransportConnectionState.hosting);
    return gameCode;
  }

  void _onClientConnected(Socket socket) {
    final id = '${socket.remoteAddress.address}:${socket.remotePort}';
    _clientSockets[id] = socket;
    final decoder = GameMessageDecoder();
    _clientDecoders[id] = decoder;
    socket.listen(
      (bytes) {
        for (final message in decoder.addBytes(bytes)) {
          _incomingController.add(message);
        }
      },
      onDone: () {
        _clientSockets.remove(id);
        _clientDecoders.remove(id);
      },
      onError: (Object _) {
        _clientSockets.remove(id);
        _clientDecoders.remove(id);
      },
      cancelOnError: true,
    );
  }

  @override
  Stream<DiscoveredGame> discoverGames() {
    _connectionStateController.add(TransportConnectionState.discovering);
    _listenForBroadcasts();
    return _discoveredController.stream;
  }

  Future<void> _listenForBroadcasts() async {
    _discoverySocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _discoveryPort,
      reuseAddress: true,
    );
    _discoverySub = _discoverySocket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = _discoverySocket!.receive();
      if (datagram == null) return;

      final text = utf8.decode(datagram.data);
      if (!text.startsWith(_discoveryPrefix)) return;
      final parts = text.substring(_discoveryPrefix.length).split('|');
      if (parts.length != 2) return;

      _discoveredController.add(DiscoveredGame(
        // The sender's IP address doubles as the connect target for WiFi
        // — see connectToGame below.
        hostId: datagram.address.address,
        hostName: parts[0],
        gameCode: parts[1],
      ));
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await _discoverySub?.cancel();
    _discoverySocket?.close();
    _discoverySocket = null;
  }

  @override
  Future<void> connectToGame(DiscoveredGame game) async {
    _connectionStateController.add(TransportConnectionState.connecting);
    await stopDiscovery();

    _hostSocket = await Socket.connect(game.hostId, _dataPort);
    _hostSocketSub = _hostSocket!.listen(
      (bytes) {
        for (final message in _hostDecoder.addBytes(bytes)) {
          _incomingController.add(message);
        }
      },
      onDone: () =>
          _connectionStateController.add(TransportConnectionState.disconnected),
      onError: (Object _) =>
          _connectionStateController.add(TransportConnectionState.disconnected),
      cancelOnError: true,
    );

    _connectionStateController.add(TransportConnectionState.connected);
  }

  @override
  Future<void> send(GameMessage message) async {
    final frame = frameGameMessage(message);
    if (_isHost) {
      for (final socket in _clientSockets.values) {
        socket.add(frame);
      }
    } else {
      _hostSocket?.add(frame);
    }
  }

  @override
  Future<void> disconnect() async {
    _advertiseTimer?.cancel();
    await _serverSub?.cancel();
    await _serverSocket?.close();
    await _discoverySub?.cancel();
    _discoverySocket?.close();
    for (final socket in _clientSockets.values) {
      await socket.close();
    }
    _clientSockets.clear();
    _clientDecoders.clear();
    await _hostSocketSub?.cancel();
    await _hostSocket?.close();
    _hostSocket = null;
    _connectionStateController.add(TransportConnectionState.disconnected);
  }
}
