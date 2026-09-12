import 'package:flutter_test/flutter_test.dart';

import 'package:app_boilerplate/features/sets_game/domain/multiplayer/game_message.dart';
import 'package:app_boilerplate/features/sets_game/domain/multiplayer/message_framer.dart';

void main() {
  group('frameGameMessage / GameMessageDecoder', () {
    test('round-trips a single message delivered whole', () {
      const message = PlayerJoined(playerId: 'p1', playerName: 'Alex');
      final frame = frameGameMessage(message);

      final decoder = GameMessageDecoder();
      final result = decoder.addBytes(frame);

      expect(result, hasLength(1));
      final decoded = result.first as PlayerJoined;
      expect(decoded.playerId, 'p1');
      expect(decoded.playerName, 'Alex');
    });

    test('reassembles a message delivered in arbitrary small pieces', () {
      const message = ClaimAttempt(
        playerId: 'p2',
        boardIndices: [0, 4, 9],
        clientTimestampMs: 12345,
      );
      final frame = frameGameMessage(message);
      final decoder = GameMessageDecoder();

      final allResults = <GameMessage>[];
      // Feed it 3 bytes at a time, simulating small BLE packets arriving
      // one after another.
      for (var i = 0; i < frame.length; i += 3) {
        final end = (i + 3 > frame.length) ? frame.length : i + 3;
        allResults.addAll(decoder.addBytes(frame.sublist(i, end)));
      }

      expect(allResults, hasLength(1));
      final decoded = allResults.first as ClaimAttempt;
      expect(decoded.boardIndices, [0, 4, 9]);
      expect(decoded.clientTimestampMs, 12345);
    });

    test('splits two messages delivered concatenated in one delivery', () {
      const first = PlayerLeft(playerId: 'p1');
      const second = PlayerLeft(playerId: 'p2');
      final combined = [
        ...frameGameMessage(first),
        ...frameGameMessage(second),
      ];

      final decoder = GameMessageDecoder();
      final result = decoder.addBytes(combined);

      expect(result, hasLength(2));
      expect((result[0] as PlayerLeft).playerId, 'p1');
      expect((result[1] as PlayerLeft).playerId, 'p2');
    });

    test('returns nothing until a full frame has arrived', () {
      const message = Heartbeat();
      final frame = frameGameMessage(message);
      final decoder = GameMessageDecoder();

      // Feed everything except the last byte.
      final result = decoder.addBytes(frame.sublist(0, frame.length - 1));
      expect(result, isEmpty);

      // Now the final byte completes the frame.
      final finalResult = decoder.addBytes([frame.last]);
      expect(finalResult, hasLength(1));
      expect(finalResult.first, isA<Heartbeat>());
    });
  });
}
