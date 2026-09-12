import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/difficulty.dart';

/// Holds the currently-selected difficulty, chosen on the home screen
/// before starting a game. SetsGameController reads this once when it
/// builds (i.e. when the game screen first opens) to set the bot pacing.
class DifficultyController extends Notifier<GameDifficulty> {
  @override
  GameDifficulty build() => GameDifficulty.moderate;

  void select(GameDifficulty difficulty) => state = difficulty;
}

final difficultyControllerProvider =
    NotifierProvider<DifficultyController, GameDifficulty>(
  DifficultyController.new,
);
