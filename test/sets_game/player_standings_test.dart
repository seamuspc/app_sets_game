import 'package:flutter_test/flutter_test.dart';

import 'package:app_boilerplate/features/sets_game/domain/player.dart';
import 'package:app_boilerplate/features/sets_game/domain/player_standings.dart';

void main() {
  group('computeStandings', () {
    test('sole highest score is leading', () {
      final players = [
        const Player(id: 'a', name: 'A', score: 3),
        const Player(id: 'b', name: 'B', score: 1),
      ];
      final result = computeStandings(players);
      expect(result.standings['a'], PlayerStanding.leading);
      expect(result.currentLeaderId, 'a');
    });

    test('sole lowest score is last, with 3+ players', () {
      final players = [
        const Player(id: 'a', name: 'A', score: 5),
        const Player(id: 'b', name: 'B', score: 3),
        const Player(id: 'c', name: 'C', score: 0),
      ];
      final result = computeStandings(players);
      expect(result.standings['c'], PlayerStanding.last);
      expect(result.standings['b'], PlayerStanding.neutral);
    });

    test('a tie for first means nobody is leading', () {
      final players = [
        const Player(id: 'a', name: 'A', score: 2),
        const Player(id: 'b', name: 'B', score: 2),
        const Player(id: 'c', name: 'C', score: 0),
      ];
      final result = computeStandings(players);
      expect(result.standings['a'], PlayerStanding.neutral);
      expect(result.standings['b'], PlayerStanding.neutral);
      expect(result.currentLeaderId, isNull);
    });

    test('everyone tied means nobody leads or trails', () {
      final players = [
        const Player(id: 'a', name: 'A', score: 4),
        const Player(id: 'b', name: 'B', score: 4),
      ];
      final result = computeStandings(players);
      expect(result.standings['a'], PlayerStanding.neutral);
      expect(result.standings['b'], PlayerStanding.neutral);
    });

    test('previous sole leader who lost it gets justLostLead once', () {
      // 'a' was leading last round (passed in as previousLeaderId), but
      // 'b' has since caught up and passed them.
      final players = [
        const Player(id: 'a', name: 'A', score: 3),
        const Player(id: 'b', name: 'B', score: 5),
      ];
      final result = computeStandings(players, previousLeaderId: 'a');
      expect(result.standings['a'], PlayerStanding.justLostLead);
      expect(result.standings['b'], PlayerStanding.leading);
      expect(result.currentLeaderId, 'b');
    });

    test('single player is neutral, not leading or last', () {
      final players = [const Player(id: 'a', name: 'A', score: 10)];
      final result = computeStandings(players);
      expect(result.standings['a'], PlayerStanding.neutral);
    });

    test('empty player list returns empty standings', () {
      final result = computeStandings([]);
      expect(result.standings, isEmpty);
      expect(result.currentLeaderId, isNull);
    });
  });
}
