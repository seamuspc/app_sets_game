import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_plugin/flutter_bluetooth_plugin.dart';

import 'game_message.dart';
import 'game_transport.dart';
import 'message_framer.dart';

/// Custom 128-bit UUIDs for this app's GATT service/characteristic.
/// These identify our game specifically during scanning, so we don't
/// pick up random unrelated BLE devices.
const _serviceUuid = '5f2b1a00-73f1-4e2c-9d3a-1a2b3c4d5e6f';
const _characteristicUuid = '5f2b1a01-73f1-4e2c-9d3a-1a2b3c4d5e6f';

/// Safe payload size per BLE write/notify before MTU negotiation
/// completes. Real devices can usually negotiate higher, but staying
/// conservative here avoids write failures on older hardware.
const _maxChunkSize = 180;

/// Bluetooth transport using raw BLE GATT — genuinely cross-platform
/// between Android and iOS, because GATT is a real Bluetooth SIG
/// standard (unlike Nearby Connections / Multipeer Connectivity, which
/// are OS-proprietary and don't interoperate). The host runs as a BLE
/// peripheral advertising a local GATT service; clients run as BLE
/// central, scanning for and connecting to that service.
///
/// Real constraint: BLE discovery/pairing needs both devices in the
/// foreground — see TransportMode.caveat. An already-open connection
/// can generally survive brief backgrounding if the right iOS
/// background modes are declared in Info.plist (bluetooth-central /
/// bluetooth-peripheral), but that's a platform-config step outside
/// this file.
class BleGameTransport implements GameTransport {
  BleGameTransport() : _bluetooth = FlutterBluetoothPlugin();

  final FlutterBluetoothPlugin _bluetooth;

  final _connectionStateController =
      StreamController<TransportConnectionState>.broadcast();
  final _incomingController = StreamController<GameMessage>.broadcast();
  final _discoveredController = StreamController<DiscoveredGame>.broadcast();

  StreamSubscription? _scanSub;
  StreamSubscription? _notifySub;
  StreamSubscription? _serverRequestsSub;

  bool _isHost = false;
  String? _connectedHostDeviceId; // client role
  final Set<String> _connectedClientDeviceIds = {}; // host role

  final _clientSideDecoder = GameMessageDecoder();
  final Map<String, GameMessageDecoder> _hostSideDecoders = {};

  @override
  Stream<TransportConnectionState> get connectionState =>
      _connectionStateController.stream;

  @override
  Stream<GameMessage> get incomingMessages => _incomingController.stream;

  Future<void> _ensureBluetoothReady() async {
    await _bluetooth.requestPermissions();
    final state = await _bluetooth.getAdapterState();
    if (state != BluetoothAdapterState.poweredOn) {
      final opened = await _bluetooth.requestEnable();
      if (!opened) await _bluetooth.openBluetoothSettings();
    }
  }

  @override
  Future<String> startHosting({required String hostName}) async {
    await _ensureBluetoothReady();
    _isHost = true;

    if (!await _bluetooth.isPeripheralSupported()) {
      throw StateError(
        'This device does not support acting as a BLE peripheral — '
        'try WiFi mode instead.',
      );
    }

    await _bluetooth.setGattServerServices([
      BluetoothGattService(
        uuid: _serviceUuid,
        characteristics: [
          BluetoothGattCharacteristic(
            uuid: _characteristicUuid,
            serviceUuid: _serviceUuid,
            properties: const ['read', 'write', 'writeWithoutResponse', 'notify'],
            permissions: const ['read', 'write'],
            value: Uint8List(0),
          ),
        ],
      ),
    ]);

    _serverRequestsSub =
        _bluetooth.gattServerRequests.listen(_onGattServerRequest);

    final gameCode =
        (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();

    // The game code rides in the advertised local name (host#code) so a
    // scanning client can show it before ever connecting — connecting
    // itself only needs the service UUID filter to find candidates.
    await _bluetooth.startAdvertising(
      advertisementData: BluetoothAdvertisementData(
        localName: '$hostName#$gameCode',
        serviceUuids: const [_serviceUuid],
        includeDeviceName: true,
      ),
      settings: const BluetoothAdvertisingSettings(
        mode: BluetoothAdvertisingMode.lowLatency,
        connectable: true,
      ),
    );

    _connectionStateController.add(TransportConnectionState.hosting);
    return gameCode;
  }

  void _onGattServerRequest(BluetoothGattServerRequest event) {
    _connectedClientDeviceIds.add(event.deviceId);
    if (event.value == null) return;
    final decoder =
        _hostSideDecoders.putIfAbsent(event.deviceId, () => GameMessageDecoder());
    for (final message in decoder.addBytes(event.value!)) {
      _incomingController.add(message);
    }
  }

  @override
  Stream<DiscoveredGame> discoverGames() {
    _connectionStateController.add(TransportConnectionState.discovering);
    _startScan();
    return _discoveredController.stream;
  }

  Future<void> _startScan() async {
    await _ensureBluetoothReady();
    _scanSub = _bluetooth.scanResults.listen((result) {
      final localName = result.localName ?? result.device.name;
      if (localName == null || !localName.contains('#')) return;
      final parts = localName.split('#');
      if (parts.length != 2) return;
      _discoveredController.add(DiscoveredGame(
        hostId: result.device.id,
        hostName: parts[0],
        gameCode: parts[1],
      ));
    });

    await _bluetooth.startScan(
      serviceUuids: const [_serviceUuid],
      timeout: const Duration(seconds: 30),
    );
  }

  @override
  Future<void> stopDiscovery() async {
    await _bluetooth.stopScan();
    await _scanSub?.cancel();
  }

  @override
  Future<void> connectToGame(DiscoveredGame game) async {
    _connectionStateController.add(TransportConnectionState.connecting);
    await stopDiscovery();

    await _bluetooth.connect(game.hostId, timeout: const Duration(seconds: 15));
    _connectedHostDeviceId = game.hostId;

    await _bluetooth.discoverServices(game.hostId);

    _notifySub = _bluetooth.characteristicValues.listen((event) {
      if (event.characteristicUuid != _characteristicUuid) return;
      for (final message in _clientSideDecoder.addBytes(event.value)) {
        _incomingController.add(message);
      }
    });

    await _bluetooth.setCharacteristicNotification(
      deviceId: game.hostId,
      serviceUuid: _serviceUuid,
      characteristicUuid: _characteristicUuid,
      enable: true,
    );

    _connectionStateController.add(TransportConnectionState.connected);
  }

  @override
  Future<void> send(GameMessage message) async {
    final frame = frameGameMessage(message);
    final chunks = _chunk(frame, _maxChunkSize);

    if (_isHost) {
      // notifyGattServerCharacteristic broadcasts to every subscribed
      // central — i.e. every connected client — matching our
      // host-broadcasts-to-all design.
      for (final chunk in chunks) {
        final bytes = Uint8List.fromList(chunk);
        await _bluetooth.updateLocalCharacteristicValue(
          serviceUuid: _serviceUuid,
          characteristicUuid: _characteristicUuid,
          value: bytes,
        );
        await _bluetooth.notifyGattServerCharacteristic(
          serviceUuid: _serviceUuid,
          characteristicUuid: _characteristicUuid,
          value: bytes,
          confirm: false,
        );
      }
    } else {
      final hostId = _connectedHostDeviceId;
      if (hostId == null) return;
      for (final chunk in chunks) {
        await _bluetooth.writeCharacteristic(
          deviceId: hostId,
          serviceUuid: _serviceUuid,
          characteristicUuid: _characteristicUuid,
          value: Uint8List.fromList(chunk),
          writeType: BluetoothWriteType.withResponse,
        );
      }
    }
  }

  List<List<int>> _chunk(List<int> bytes, int size) {
    final chunks = <List<int>>[];
    for (var i = 0; i < bytes.length; i += size) {
      final end = (i + size > bytes.length) ? bytes.length : i + size;
      chunks.add(bytes.sublist(i, end));
    }
    return chunks;
  }

  @override
  Future<void> disconnect() async {
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _serverRequestsSub?.cancel();

    if (_isHost) {
      await _bluetooth.stopAdvertising();
      await _bluetooth.clearGattServerServices();
      _connectedClientDeviceIds.clear();
      _hostSideDecoders.clear();
    } else if (_connectedHostDeviceId != null) {
      await _bluetooth.disconnect(_connectedHostDeviceId!);
      _connectedHostDeviceId = null;
    }

    _connectionStateController.add(TransportConnectionState.disconnected);
  }
}
