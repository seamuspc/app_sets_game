import 'dart:math';

import 'set_card.dart';

/// Builds the full 81-card SET deck: every combination of the three
/// colors, three shapes, three shadings, and counts 1–3, exactly once.
List<SetCard> buildFullDeck() {
  final deck = <SetCard>[];
  for (final color in CardColor.values) {
    for (final shape in CardShape.values) {
      for (final shading in CardShading.values) {
        for (var count = 1; count <= 3; count++) {
          deck.add(SetCard(
            color: color,
            shape: shape,
            shading: shading,
            count: count,
          ));
        }
      }
    }
  }
  return deck;
}

/// Returns a shuffled copy of [buildFullDeck] — pass in a [Random] with a
/// fixed seed in tests for deterministic ordering; omit it for real games.
List<SetCard> buildShuffledDeck([Random? random]) {
  final deck = buildFullDeck();
  deck.shuffle(random ?? Random());
  return deck;
}
