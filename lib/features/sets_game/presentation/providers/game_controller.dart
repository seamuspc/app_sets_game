import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/deck.dart';
import '../../domain/difficulty.dart';
import '../../domain/game_state.dart';
import '../../domain/set_card.dart';
import '../../domain/set_rules.dart';
import 'difficulty_controller.dart';
import 'players_controller.dart';

const _initialBoardSize = 12;

/// How long the opponent's found set stays highlighted before being
/// removed/replaced.
const _highlightDuration = Duration(milliseconds: 1200);

/// How long each step of the 3-2-1 countdown shows before ticking down.
const _countdownStepDuration = Duration(seconds: 1);

class SetsGameController extends Notifier<GameState> {
  Timer? _botTimer;
  final _random = Random();

  @override
  GameState build() {
    if (kDebugMode && simulateBotPlayersInDebug) {
      _startDebugBotTimer();
      ref.onDispose(() => _botTimer?.cancel());
    }
    return _newGame();
  }

  GameState _newGame() {
    final deck = buildShuffledDeck();
    final board = deck.take(_initialBoardSize).toList();
    final remainingDeck = deck.skip(_initialBoardSize).toList();
    return _ensureBoardHasSet(
      GameState(
        deck: remainingDeck,
        board: board,
        selectedIndices: const {},
        score: 0,
        lastGuessResult: SetGuessResult.none,
        isGameOver: false,
      ),
    );
  }

  void startNewGame() {
    _botTimer?.cancel();
    state = _newGame();
    ref.read(playersControllerProvider.notifier).reset();
    if (kDebugMode && simulateBotPlayersInDebug) {
      _startDebugBotTimer();
    }
  }

  /// TEMPORARY: periodically has a random bot "claim" a real valid set
  /// from the current board, so the opponent-found-set animation/pause/
  /// countdown sequence has something real to show before actual
  /// networked opponents exist. Delete this whole method (and the timer
  /// field above) once the Bluetooth layer is wiring in real player
  /// moves instead.
  void _startDebugBotTimer() {
    final interval = ref.read(difficultyControllerProvider).botInterval;
    _botTimer = Timer.periodic(interval, (_) {
      if (state.isGameOver || state.pausedForOpponentSet) return;
      final bots =
          ref.read(playersControllerProvider).players.where((p) => !p.isLocal);
      if (bots.isEmpty) return;
      final botList = bots.toList();
      final bot = botList[_random.nextInt(botList.length)];
      claimSetForOpponent(bot.id, bot.name);
    });
  }

  /// Deals 3 more cards onto the board if it currently has no valid set —
  /// this is a real SET rule, not a bug: physical decks do the same thing.
  /// Repeats in case the deck runs unusually dry on valid combinations.
  GameState _ensureBoardHasSet(GameState current) {
    var next = current;
    while (!boardHasValidSet(next.board) && next.deck.isNotEmpty) {
      final extraCount = next.deck.length >= 3 ? 3 : next.deck.length;
      final extra = next.deck.take(extraCount).toList();
      next = next.copyWith(
        board: [...next.board, ...extra],
        deck: next.deck.skip(extraCount).toList(),
      );
    }
    final isOver = next.deck.isEmpty && !boardHasValidSet(next.board);
    return next.copyWith(isGameOver: isOver);
  }

  /// Toggles a card's selection. Once 3 cards are selected, automatically
  /// checks whether they form a valid set.
  void toggleCardSelection(int boardIndex) {
    if (state.isGameOver || state.pausedForOpponentSet) return;

    final selected = Set<int>.from(state.selectedIndices);
    if (selected.contains(boardIndex)) {
      selected.remove(boardIndex);
      state = state.copyWith(selectedIndices: selected);
      return;
    }

    if (selected.length >= 3) return; // already have 3 picked
    selected.add(boardIndex);
    state = state.copyWith(selectedIndices: selected);

    if (selected.length == 3) {
      _checkSelection(selected);
    }
  }

  /// Called when an opponent finds a set — pauses local input, highlights
  /// the 3 cards they claimed, removes and replaces them, then runs a
  /// 3-2-1 countdown before handing control back. This is what the
  /// debug bot timer calls, and later, what a real network message from
  /// an opponent's move should call too.
  Future<void> claimSetForOpponent(String playerId, String playerName) async {
    if (state.isGameOver || state.pausedForOpponentSet) return;

    final indices = findFirstValidSetIndices(state.board);
    if (indices == null) return; // nothing valid to claim right now

    appLogger.i('$playerName claimed a set: $indices');

    // Phase 1: pause input and highlight the claimed cards.
    state = state.copyWith(
      pausedForOpponentSet: true,
      opponentFoundIndices: indices,
      opponentName: playerName,
      selectedIndices: const {}, // clear any local selection in progress
    );
    await Future<void>.delayed(_highlightDuration);

    // Phase 2: remove and replace those cards, then credit the score.
    _replaceFoundCards(indices);
    state = state.copyWith(opponentFoundIndices: const []);
    ref.read(playersControllerProvider.notifier).incrementScore(playerId);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    // Phase 3: 3-2-1 countdown before resuming.
    for (final tick in [3, 2, 1]) {
      state = state.copyWith(countdown: tick);
      await Future<void>.delayed(_countdownStepDuration);
    }
    state = state.copyWith(countdown: 0, pausedForOpponentSet: false);
  }

  void _checkSelection(Set<int> selected) {
    final indices = selected.toList();
    final cards = indices.map((i) => state.board[i]).toList();
    final valid = isValidSet(cards[0], cards[1], cards[2]);

    appLogger.i(
      valid ? 'Valid set found: $cards' : 'Invalid guess: $cards',
    );

    state = state.copyWith(
      lastGuessResult: valid ? SetGuessResult.valid : SetGuessResult.invalid,
      score: valid ? state.score + 1 : state.score,
    );

    if (valid) {
      ref.read(playersControllerProvider.notifier).incrementScore(localPlayerId);
      _replaceFoundCards(indices);
    }
    // Invalid guesses are cleared by the UI after a short delay via
    // clearGuessFeedback(), so the player has a moment to see the flash.
  }

  void _replaceFoundCards(List<int> foundIndices) {
    final sortedIndices = List<int>.from(foundIndices)..sort();
    final board = List<SetCard>.from(state.board);
    final deck = List<SetCard>.from(state.deck);

    if (deck.isNotEmpty && board.length <= _initialBoardSize) {
      // Normal case: deal a fresh card into each found slot, keeping the
      // board at its usual size.
      for (final index in sortedIndices) {
        board[index] = deck.removeAt(0);
      }
    } else {
      // Deck is empty, or the board had already grown past 12 from an
      // earlier top-up — just remove the found cards instead, shrinking
      // the board. Remove from the end first so earlier indices stay valid.
      for (final index in sortedIndices.reversed) {
        board.removeAt(index);
      }
    }

    final next = state.copyWith(
      board: board,
      deck: deck,
      selectedIndices: const {},
    );
    state = _ensureBoardHasSet(next);
  }

  /// Called by the UI after showing invalid-guess feedback briefly, to
  /// reset selection and clear the red flash.
  void clearGuessFeedback() {
    state = state.copyWith(
      selectedIndices: const {},
      lastGuessResult: SetGuessResult.none,
    );
  }
}

final setsGameControllerProvider =
    NotifierProvider<SetsGameController, GameState>(SetsGameController.new);
