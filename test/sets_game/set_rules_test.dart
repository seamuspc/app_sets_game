import 'package:flutter_test/flutter_test.dart';

import 'package:app_boilerplate/features/sets_game/domain/deck.dart';
import 'package:app_boilerplate/features/sets_game/domain/set_card.dart';
import 'package:app_boilerplate/features/sets_game/domain/set_rules.dart';

void main() {
  group('buildFullDeck', () {
    test('contains exactly 81 unique cards', () {
      final deck = buildFullDeck();
      expect(deck.length, 81);
      expect(deck.toSet().length, 81); // no duplicates
    });
  });

  group('isValidSet', () {
    test('all attributes the same is valid', () {
      const a = SetCard(
        color: CardColor.red,
        shape: CardShape.diamond,
        shading: CardShading.solid,
        count: 1,
      );
      const b = SetCard(
        color: CardColor.red,
        shape: CardShape.diamond,
        shading: CardShading.solid,
        count: 1,
      );
      const c = SetCard(
        color: CardColor.red,
        shape: CardShape.diamond,
        shading: CardShading.solid,
        count: 1,
      );
      // Not realistic (same card 3x can't happen with a real deck) but
      // validates the "all same" branch of the rule in isolation.
      expect(isValidSet(a, b, c), isTrue);
    });

    test('all attributes different is valid', () {
      const a = SetCard(
        color: CardColor.red,
        shape: CardShape.diamond,
        shading: CardShading.solid,
        count: 1,
      );
      const b = SetCard(
        color: CardColor.green,
        shape: CardShape.squiggle,
        shading: CardShading.striped,
        count: 2,
      );
      const c = SetCard(
        color: CardColor.purple,
        shape: CardShape.oval,
        shading: CardShading.empty,
        count: 3,
      );
      expect(isValidSet(a, b, c), isTrue);
    });

    test('two same one different on any attribute is invalid', () {
      const a = SetCard(
        color: CardColor.red,
        shape: CardShape.diamond,
        shading: CardShading.solid,
        count: 1,
      );
      const b = SetCard(
        color: CardColor.red, // same color as a
        shape: CardShape.squiggle,
        shading: CardShading.striped,
        count: 2,
      );
      const c = SetCard(
        color: CardColor.purple, // different from both — invalid
        shape: CardShape.oval,
        shading: CardShading.empty,
        count: 3,
      );
      expect(isValidSet(a, b, c), isFalse);
    });
  });

  group('findFirstValidSetIndices', () {
    test('finds a set when one exists', () {
      final board = [
        const SetCard(
          color: CardColor.red,
          shape: CardShape.diamond,
          shading: CardShading.solid,
          count: 1,
        ),
        const SetCard(
          color: CardColor.green,
          shape: CardShape.squiggle,
          shading: CardShading.striped,
          count: 2,
        ),
        const SetCard(
          color: CardColor.purple,
          shape: CardShape.oval,
          shading: CardShading.empty,
          count: 3,
        ),
      ];
      expect(findFirstValidSetIndices(board), [0, 1, 2]);
    });

    test('returns null when no set exists', () {
      final board = [
        const SetCard(
          color: CardColor.red,
          shape: CardShape.diamond,
          shading: CardShading.solid,
          count: 1,
        ),
        const SetCard(
          color: CardColor.red,
          shape: CardShape.diamond,
          shading: CardShading.solid,
          count: 2,
        ),
      ];
      expect(findFirstValidSetIndices(board), isNull);
    });
  });
}
