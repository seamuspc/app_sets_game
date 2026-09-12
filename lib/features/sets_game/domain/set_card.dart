/// The three colors a SET card can have.
enum CardColor { red, green, purple }

/// The three shapes a SET card can have.
enum CardShape { diamond, squiggle, oval }

/// The three fill styles a SET card can have.
enum CardShading { solid, striped, empty }

/// A single SET card: every card is a unique combination of color, shape,
/// shading, and count (1–3). There are exactly 3×3×3×3 = 81 such cards —
/// that's the full deck, see [buildFullDeck] in deck.dart.
///
/// This class is deliberately plain Dart with no Flutter imports — the
/// rules of SET don't care how a card is drawn on screen.
class SetCard {
  const SetCard({
    required this.color,
    required this.shape,
    required this.shading,
    required this.count,
  }) : assert(count >= 1 && count <= 3, 'count must be 1, 2, or 3');

  final CardColor color;
  final CardShape shape;
  final CardShading shading;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is SetCard &&
      other.color == color &&
      other.shape == shape &&
      other.shading == shading &&
      other.count == count;

  @override
  int get hashCode => Object.hash(color, shape, shading, count);

  @override
  String toString() =>
      'SetCard($count $color $shading $shape${count > 1 ? 's' : ''})';
}
