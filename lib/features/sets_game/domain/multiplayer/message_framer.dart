import 'dart:convert';
import 'dart:typed_data';

import 'game_message.dart';

/// Encodes a GameMessage into a length-prefixed byte frame: 4 bytes
/// (big-endian) giving the payload length, followed by the UTF-8 JSON
/// payload. Needed because neither transport delivers clean message
/// boundaries on its own — TCP is just a continuous byte stream, and BLE
/// writes/notifies may need to be split across multiple packets if a
/// message is bigger than the negotiated MTU. This framing lets the
/// receiving side (see [GameMessageDecoder]) find message boundaries
/// regardless of how the bytes happened to arrive in pieces.
Uint8List frameGameMessage(GameMessage message) {
  final payload = utf8.encode(jsonEncode(message.toJson()));
  final frame = Uint8List(4 + payload.length);
  ByteData.view(frame.buffer).setUint32(0, payload.length, Endian.big);
  frame.setRange(4, frame.length, payload);
  return frame;
}

/// Reassembles length-prefixed frames from bytes that may arrive in
/// arbitrary pieces. Feed it raw bytes as they come in (one BLE
/// notification at a time, or whatever chunk size a TCP socket happens
/// to deliver) and it returns any complete messages that became
/// available as a result. Keeps partial data buffered across calls, so
/// callers never need to reason about where a message boundary falls
/// relative to how the transport delivered the bytes.
class GameMessageDecoder {
  final _buffer = BytesBuilder();

  /// Feed raw bytes as they arrive. Returns 0 or more complete messages
  /// — usually 0 or 1, but could be more if several small messages
  /// arrived in a single delivery.
  List<GameMessage> addBytes(List<int> bytes) {
    _buffer.add(bytes);
    final ready = <GameMessage>[];

    while (true) {
      final buffered = _buffer.toBytes();
      if (buffered.length < 4) break;

      final length =
          ByteData.sublistView(buffered, 0, 4).getUint32(0, Endian.big);
      if (buffered.length < 4 + length) break; // full frame not in yet

      final payload = buffered.sublist(4, 4 + length);
      final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      ready.add(GameMessage.fromJson(json));

      final remainder = buffered.sublist(4 + length);
      _buffer.clear();
      if (remainder.isNotEmpty) _buffer.add(remainder);
    }

    return ready;
  }
}
