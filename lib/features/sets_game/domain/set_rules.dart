import 'set_card.dart';

/// The classic SET rule: three cards form a valid set if, for EVERY
/// attribute (color, shape, shading, count), the three cards are either
/// all the same or all different. If even one attribute has exactly two
/// matching and one different, it's not a set.
bool isValidSet(SetCard a, SetCard b, SetCard c) {
  return _allSameOrAllDifferent([a.color, b.color, c.color]) &&
      _allSameOrAllDifferent([a.shape, b.shape, c.shape]) &&
      _allSameOrAllDifferent([a.shading, b.shading, c.shading]) &&
      _allSameOrAllDifferent([a.count, b.count, c.count]);
}

bool _allSameOrAllDifferent<T>(List<T> values) {
  final unique = values.toSet();
  // 1 unique value = all same. 3 unique values = all different.
  // 2 unique values means two matched and one didn't — invalid.
  return unique.length == 1 || unique.length == values.length;
}

/// Scans a board for the first valid set it can find (by index into
/// [board]), or null if there isn't one. Used both to validate a
/// player's guess isn't the only option, and — more importantly — to
/// decide whether the board needs extra cards dealt onto it, since a
/// SET board should always have at least one valid set available.
List<int>? findFirstValidSetIndices(List<SetCard> board) {
  for (var i = 0; i < board.length; i++) {
    for (var j = i + 1; j < board.length; j++) {
      for (var k = j + 1; k < board.length; k++) {
        if (isValidSet(board[i], board[j], board[k])) {
          return [i, j, k];
        }
      }
    }
  }
  return null;
}

/// Convenience check for whether any valid set exists on the board at all.
bool boardHasValidSet(List<SetCard> board) =>
    findFirstValidSetIndices(board) != null;
