import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/game_state.dart';
import '../../domain/player.dart';
import '../../domain/player_standings.dart';
import '../providers/difficulty_controller.dart';
import '../providers/game_controller.dart';
import '../providers/players_controller.dart';
import '../widgets/countdown_overlay.dart';
import '../widgets/difficulty_bars_icon.dart';
import '../widgets/leaderboard_panel.dart';
import '../widgets/rank_border_overlay.dart';
import '../widgets/set_card_widget.dart';
import '../widgets/standing_overlay.dart';

class SetsGameScreen extends ConsumerStatefulWidget {
  const SetsGameScreen({super.key});

  @override
  ConsumerState<SetsGameScreen> createState() => _SetsGameScreenState();
}

class _SetsGameScreenState extends ConsumerState<SetsGameScreen> {
  Timer? _feedbackTimer;
  Timer? _standingFlashTimer;
  Timer? _leaderboardAutoCloseTimer;
  bool _showStandingOverlay = false;
  bool _isLeaderboardExpanded = false;
  String _flashMessage = '';
  Color _flashColor = Colors.grey;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _standingFlashTimer?.cancel();
    _leaderboardAutoCloseTimer?.cancel();
    super.dispose();
  }

  /// After an invalid guess, briefly leave the red highlight up so the
  /// player can see what they picked, then clear it automatically.
  void _scheduleFeedbackClear() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        ref.read(setsGameControllerProvider.notifier).clearGuessFeedback();
      }
    });
  }

  /// Shows the translucent standing/leaderboard overlay with [message] for
  /// 1.5s, then hides it again — this is meant to flash briefly, not sit
  /// as persistent UI, per the design decision.
  void _flashStandingOverlay(String message, Color color) {
    _standingFlashTimer?.cancel();
    setState(() {
      _flashMessage = message;
      _flashColor = color;
      _showStandingOverlay = true;
    });
    _standingFlashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showStandingOverlay = false);
    });
  }

  /// Toggles the persistent leaderboard panel. Opening it starts a
  /// 2-second auto-close timer — tapping again early cancels that timer
  /// and closes it immediately instead.
  void _toggleLeaderboard() {
    _leaderboardAutoCloseTimer?.cancel();
    if (_isLeaderboardExpanded) {
      setState(() => _isLeaderboardExpanded = false);
      return;
    }
    setState(() => _isLeaderboardExpanded = true);
    _leaderboardAutoCloseTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLeaderboardExpanded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(setsGameControllerProvider);
    final controller = ref.read(setsGameControllerProvider.notifier);
    final playersState = ref.watch(playersControllerProvider);
    final localStanding = playersState.standingFor(localPlayerId);

    // React to a fresh invalid guess by scheduling its auto-clear. Valid
    // guesses clear their own selection immediately in the controller, so
    // only SetGuessResult.invalid needs this timer.
    ref.listen(setsGameControllerProvider, (previous, next) {
      if (next.lastGuessResult == SetGuessResult.invalid &&
          previous?.lastGuessResult != SetGuessResult.invalid) {
        _scheduleFeedbackClear();
      }
    });

    // Flash the standing overlay for four kinds of event, checked in
    // priority order so only one flash fires per update:
    //  1. The LOCAL player's own standing changed (took lead/lost lead/last)
    //  2. Someone ELSE became the new sole leader
    //  3. ANY player's score just landed on a multiple of 2 (a milestone)
    //  4. Any OTHER player's score went up (they found a set) — the
    //     generic fallback when nothing more specific applies
    // Ordinary updates that don't match any of these don't trigger
    // anything.
    ref.listen(playersControllerProvider, (previous, next) {
      if (previous == null) return;

      final prevLocalStanding = previous.standingFor(localPlayerId);
      final nextLocalStanding = next.standingFor(localPlayerId);
      if (prevLocalStanding != nextLocalStanding &&
          nextLocalStanding != PlayerStanding.neutral) {
        final message = switch (nextLocalStanding) {
          PlayerStanding.leading => "You're in the lead!",
          PlayerStanding.justLostLead => 'You lost the lead!',
          PlayerStanding.last => "You're in last place",
          PlayerStanding.neutral => '',
        };
        final color = switch (nextLocalStanding) {
          PlayerStanding.leading => Colors.green,
          PlayerStanding.justLostLead => Colors.orange,
          PlayerStanding.last => Colors.red,
          PlayerStanding.neutral => Colors.grey,
        };
        _flashStandingOverlay(message, color);
        return;
      }

      if (next.currentLeaderId != null &&
          next.currentLeaderId != previous.currentLeaderId) {
        Player? leader;
        for (final p in next.players) {
          if (p.id == next.currentLeaderId) {
            leader = p;
            break;
          }
        }
        if (leader != null && !leader.isLocal) {
          _flashStandingOverlay('${leader.name} took the lead!', Colors.blueGrey);
          return;
        }
      }

      // Milestone check: did anyone's score just become an even number?
      // (score > 0 excludes the trivial "starts at 0" case.) Checked
      // ahead of the generic "found a set" fallback below, so a score
      // landing on a multiple of 2 gets this message instead.
      for (final player in next.players) {
        int? prevScore;
        for (final p in previous.players) {
          if (p.id == player.id) {
            prevScore = p.score;
            break;
          }
        }
        final justScored = prevScore != null && player.score > prevScore;
        if (justScored && player.score > 0 && player.score % 2 == 0) {
          final who = player.isLocal ? 'You' : player.name;
          _flashStandingOverlay(
            '$who reached ${player.score} sets!',
            Colors.purple,
          );
          return;
        }
      }

      for (final player in next.players) {
        if (player.isLocal) continue;
        int? prevScore;
        for (final p in previous.players) {
          if (p.id == player.id) {
            prevScore = p.score;
            break;
          }
        }
        if (prevScore != null && player.score > prevScore) {
          _flashStandingOverlay('${player.name} found a set!', Colors.blueGrey);
          return;
        }
      }
    });

    return Stack(
      children: [
        Scaffold(
      // Fixed light "table" background regardless of system dark mode —
      // the white cards and their selection borders lose contrast
      // against a near-black scaffold, so this screen intentionally
      // doesn't follow the app's theme like other screens do.
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0F2F5),
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SET'),
            Text(
              '${gameState.deck.length} cards left',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          DifficultyBarsIcon(
            difficulty: ref.watch(difficultyControllerProvider),
            maxBarHeight: 14,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
            child: Center(
              child: Text(
                'Score: ${gameState.score}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: gameState.board.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (gameState.isGameOver) _GameOverBanner(score: gameState.score),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spaceMd),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const crossAxisCount = 3;
                          const spacing = AppConstants.spaceSm;
                          final rows =
                              (gameState.board.length / crossAxisCount).ceil();

                          // Work out exactly how tall/wide each cell needs to
                          // be to fill the available space with no leftover
                          // and no overflow — recalculated on every build, so
                          // it adapts automatically if the board grows past
                          // 12 cards (the "no valid set" top-up rule) or the
                          // screen size changes (rotation, different device).
                          final cellWidth = (constraints.maxWidth -
                                  spacing * (crossAxisCount - 1)) /
                              crossAxisCount;
                          final cellHeight =
                              (constraints.maxHeight - spacing * (rows - 1)) /
                                  rows;
                          final aspectRatio = cellWidth / cellHeight;

                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: aspectRatio,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                            ),
                            itemCount: gameState.board.length,
                            itemBuilder: (context, index) {
                              final isSelected =
                                  gameState.selectedIndices.contains(index);
                              final showResult =
                                  gameState.selectedIndices.length == 3 &&
                                      isSelected &&
                                      gameState.lastGuessResult !=
                                          SetGuessResult.none;
                              final card = gameState.board[index];

                              // AnimatedSwitcher, keyed on the card itself
                              // (SetCard has value equality, and every card
                              // on the board is unique), gives a fade+scale
                              // transition automatically whenever a card at
                              // this grid position gets replaced — exactly
                              // what happens after an opponent's claimed
                              // set is removed and refilled.
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                                child: SetCardWidget(
                                  key: ValueKey(card),
                                  card: card,
                                  isSelected: isSelected,
                                  isOpponentHighlight: gameState
                                      .opponentFoundIndices
                                      .contains(index),
                                  isCorrectGuess: showResult &&
                                      gameState.lastGuessResult ==
                                          SetGuessResult.valid,
                                  isIncorrectGuess: showResult &&
                                      gameState.lastGuessResult ==
                                          SetGuessResult.invalid,
                                  onTap: () =>
                                      controller.toggleCardSelection(index),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
        ),
        RankBorderOverlay(standing: localStanding),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _showStandingOverlay ? 1 : 0,
          child: StandingOverlay(
            message: _flashMessage,
            badgeColor: _flashColor,
            players: playersState.byRank,
          ),
        ),
        if (gameState.countdown > 0)
          CountdownOverlay(count: gameState.countdown),

        // Persistent leaderboard: slides up from below the bottom edge
        // when expanded, stays open until collapsed again — separate
        // from StandingOverlay above, which only flashes briefly on
        // specific events.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _isLeaderboardExpanded ? 0 : -300,
          child: LeaderboardPanel(players: playersState.byRank),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: Material(
                color: const Color(0xFFDCEEFF).withOpacity(0.95),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xFF90C2F2), width: 1),
                ),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _toggleLeaderboard,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 280),
                      turns: _isLeaderboardExpanded ? 0.5 : 0,
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameOverBanner extends StatelessWidget {
  const _GameOverBanner({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      child: Column(
        children: [
          Text(
            'Game over! Final score: $score',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () =>
                  ref.read(setsGameControllerProvider.notifier).startNewGame(),
              child: const Text('Play again'),
            ),
          ),
        ],
      ),
    );
  }
}
