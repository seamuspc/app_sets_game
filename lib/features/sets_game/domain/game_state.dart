import 'set_card.dart';

/// Feedback shown briefly after a player submits 3 selected cards.
enum SetGuessResult { none, valid, invalid }

/// A complete, immutable snapshot of a SET game in progress.
///
/// Riverpod notifiers hand out a new instance of this on every change
/// (rather than mutating one in place) — that's what lets widgets that
/// `ref.watch` this rebuild automatically and correctly.
class GameState {
  const GameState({
    required this.deck,
    required this.board,
    required this.selectedIndices,
    required this.score,
    required this.lastGuessResult,
    required this.isGameOver,
    this.pausedForOpponentSet = false,
    this.opponentFoundIndices = const [],
    this.opponentName = '',
    this.countdown = 0,
  });

  /// Cards not yet dealt onto the board.
  final List<SetCard> deck;

  /// Cards currently visible and selectable. Normally 12, but grows by 3
  /// at a time if the board has no valid set in it.
  final List<SetCard> board;

  /// Indices into [board] the player has tapped so far (0–3 of them).
  final Set<int> selectedIndices;

  /// Total sets found so far this game.
  final int score;

  /// Feedback for the most recent 3-card guess, so the UI can flash
  /// green/red briefly. Resets to [SetGuessResult.none] once cleared.
  final SetGuessResult lastGuessResult;

  /// True once the deck is empty and the board has no valid set left —
  /// the classic end condition for a full SET game.
  final bool isGameOver;

  /// True while showing an opponent's found-set sequence: highlight the
  /// 3 cards, remove/replace them, then a 3-2-1 countdown before local
  /// input is allowed again. Card taps are ignored while this is true —
  /// see toggleCardSelection in the controller.
  final bool pausedForOpponentSet;

  /// Board indices currently being highlighted as the opponent's claimed
  /// set — only meaningful while [pausedForOpponentSet] is true, and only
  /// during the highlight phase (cleared once the cards are replaced).
  final List<int> opponentFoundIndices;

  /// Display name of whichever opponent is being shown in the current
  /// pause sequence, for the "X found a set!" framing in the UI.
  final String opponentName;

  /// 3, 2, or 1 during the post-reveal countdown before play resumes; 0
  /// when no countdown is active.
  final int countdown;

  factory GameState.initial() => const GameState(
        deck: [],
        board: [],
        selectedIndices: {},
        score: 0,
        lastGuessResult: SetGuessResult.none,
        isGameOver: false,
      );

  GameState copyWith({
    List<SetCard>? deck,
    List<SetCard>? board,
    Set<int>? selectedIndices,
    int? score,
    SetGuessResult? lastGuessResult,
    bool? isGameOver,
    bool? pausedForOpponentSet,
    List<int>? opponentFoundIndices,
    String? opponentName,
    int? countdown,
  }) {
    return GameState(
      deck: deck ?? this.deck,
      board: board ?? this.board,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      score: score ?? this.score,
      lastGuessResult: lastGuessResult ?? this.lastGuessResult,
      isGameOver: isGameOver ?? this.isGameOver,
      pausedForOpponentSet: pausedForOpponentSet ?? this.pausedForOpponentSet,
      opponentFoundIndices: opponentFoundIndices ?? this.opponentFoundIndices,
      opponentName: opponentName ?? this.opponentName,
      countdown: countdown ?? this.countdown,
    );
  }
}
