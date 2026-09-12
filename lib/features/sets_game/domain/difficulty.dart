/// The three difficulty levels a player can pick before starting a game.
/// Difficulty currently only controls how fast opponents (bots, until
/// real multiplayer exists) find sets — see [botInterval].
enum GameDifficulty { easy, moderate, hard }

extension GameDifficultyX on GameDifficulty {
  /// How many bars to show in the battery-style difficulty icon: 1 for
  /// easy, up to 3 for hard.
  int get barCount => switch (this) {
        GameDifficulty.easy => 1,
        GameDifficulty.moderate => 2,
        GameDifficulty.hard => 3,
      };

  /// How often a bot attempts to claim a set. Lower = faster = harder to
  /// beat. These are the "debug bot" numbers standing in for real
  /// opponent pacing until the Bluetooth layer exists.
  Duration get botInterval => switch (this) {
        GameDifficulty.easy => const Duration(seconds: 25),
        GameDifficulty.moderate => const Duration(seconds: 15),
        GameDifficulty.hard => const Duration(seconds: 8),
      };

  String get label => switch (this) {
        GameDifficulty.easy => 'Easy',
        GameDifficulty.moderate => 'Moderate',
        GameDifficulty.hard => 'Hard',
      };
}
