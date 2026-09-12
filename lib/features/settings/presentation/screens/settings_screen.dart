import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../sets_game/domain/multiplayer/transport_mode.dart';
import '../../../sets_game/presentation/providers/transport_mode_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMode = ref.watch(transportModeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Multiplayer connection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spaceSm),
            ...TransportMode.values.map((mode) {
              return RadioListTile<TransportMode>(
                value: mode,
                groupValue: selectedMode,
                onChanged: mode.isAvailable
                    ? (value) {
                        if (value != null) {
                          ref
                              .read(transportModeControllerProvider.notifier)
                              .select(value);
                        }
                      }
                    : null,
                title: Text(mode.label),
                subtitle: Text(mode.caveat),
              );
            }),
            const SizedBox(height: AppConstants.spaceLg),
            AppButton(
              label: 'Sign out',
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
