import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../sets_game/domain/difficulty.dart';
import '../../../sets_game/presentation/providers/difficulty_controller.dart';
import '../../../sets_game/presentation/widgets/difficulty_bars_icon.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final selectedDifficulty = ref.watch(difficultyControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Signed in as\n${user?.email ?? 'Unknown'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppConstants.spaceLg),
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppConstants.spaceSm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: GameDifficulty.values.map((difficulty) {
                  final isSelected = difficulty == selectedDifficulty;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppConstants.spaceXs),
                    child: _DifficultyOption(
                      difficulty: difficulty,
                      isSelected: isSelected,
                      onTap: () => ref
                          .read(difficultyControllerProvider.notifier)
                          .select(difficulty),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.game),
                child: const Text('Play SET'),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              OutlinedButton(
                onPressed: () => context.push(AppRoutes.lobby),
                child: const Text('Multiplayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final GameDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceSm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? primary.withOpacity(0.08) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DifficultyBarsIcon(difficulty: difficulty),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              difficulty.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
