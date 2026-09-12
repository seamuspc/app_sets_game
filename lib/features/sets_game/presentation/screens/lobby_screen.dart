import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/multiplayer/game_transport.dart';
import '../../domain/multiplayer/transport_mode.dart';
import '../providers/lobby_controller.dart';
import '../providers/lobby_state.dart';
import '../providers/players_controller.dart' show maxPlayers;
import '../providers/transport_mode_controller.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // Switching to the Join tab starts discovery automatically; leaving
      // the lobby screen entirely (see dispose) tears everything down.
      if (_tabController.index == 1 &&
          ref.read(lobbyControllerProvider).role == LobbyRole.none) {
        ref.read(lobbyControllerProvider.notifier).startDiscovering();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Deliberately not calling leaveLobby() here — navigating to the
    // actual game screen after "Start game" should keep the connection
    // alive, not tear it down. leaveLobby() is wired to an explicit
    // back/cancel action instead — see the AppBar leading button below.
    super.dispose();
  }

  String get _localPlayerName {
    final email = ref.read(authStateProvider).value?.email;
    if (email == null) return 'Player';
    return email.split('@').first;
  }

  String get _localPlayerId =>
      ref.read(authStateProvider).value?.uid ?? 'local-player';

  @override
  Widget build(BuildContext context) {
    final lobbyState = ref.watch(lobbyControllerProvider);
    final transportMode = ref.watch(transportModeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(lobbyControllerProvider.notifier).leaveLobby();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spaceMd),
            child: Center(
              child: Text(
                transportMode.label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Host'), Tab(text: 'Join')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HostTab(
            lobbyState: lobbyState,
            localPlayerId: _localPlayerId,
            localPlayerName: _localPlayerName,
          ),
          _JoinTab(
            lobbyState: lobbyState,
            localPlayerId: _localPlayerId,
            localPlayerName: _localPlayerName,
          ),
        ],
      ),
    );
  }
}

class _HostTab extends ConsumerWidget {
  const _HostTab({
    required this.lobbyState,
    required this.localPlayerId,
    required this.localPlayerName,
  });

  final LobbyState lobbyState;
  final String localPlayerId;
  final String localPlayerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lobbyState.role != LobbyRole.hosting) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lobbyState.errorMessage.isNotEmpty) ...[
                Text(
                  lobbyState.errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spaceMd),
              ],
              ElevatedButton(
                onPressed: () => ref.read(lobbyControllerProvider.notifier).startHosting(
                      localPlayerId: localPlayerId,
                      hostName: localPlayerName,
                    ),
                child: const Text('Start hosting'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.spaceLg),
      child: Column(
        children: [
          Text('Your game code', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            lobbyState.gameCode ?? '----',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppConstants.spaceLg),
          Text(
            'Waiting for players (${lobbyState.players.length}/$maxPlayers)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Expanded(
            child: ListView.builder(
              itemCount: lobbyState.players.length,
              itemBuilder: (context, index) {
                final player = lobbyState.players[index];
                final isHost = player.id == localPlayerId;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(player.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(isHost ? '${player.name} (host)' : player.name),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: lobbyState.players.length >= 2
                ? () {
                    // TODO: transition into the real multiplayer game
                    // controller once it exists, handing it
                    // ref.read(lobbyControllerProvider.notifier).activeTransport
                    // instead of opening a new connection.
                  }
                : null,
            child: const Text('Start game'),
          ),
        ],
      ),
    );
  }
}

class _JoinTab extends ConsumerWidget {
  const _JoinTab({
    required this.lobbyState,
    required this.localPlayerId,
    required this.localPlayerName,
  });

  final LobbyState lobbyState;
  final String localPlayerId;
  final String localPlayerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alreadyJoined =
        lobbyState.players.any((p) => p.id == localPlayerId);

    if (alreadyJoined) {
      return Padding(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          children: [
            const Text('Waiting for the host to start the game...'),
            const SizedBox(height: AppConstants.spaceLg),
            Expanded(
              child: ListView.builder(
                itemCount: lobbyState.players.length,
                itemBuilder: (context, index) {
                  final player = lobbyState.players[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(player.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(player.name),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    if (lobbyState.discoveredGames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppConstants.spaceMd),
              const Text('Looking for nearby games...'),
              if (lobbyState.errorMessage.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spaceMd),
                Text(
                  lobbyState.errorMessage,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      itemCount: lobbyState.discoveredGames.length,
      itemBuilder: (context, index) {
        final game = lobbyState.discoveredGames[index];
        return Card(
          child: ListTile(
            title: Text(game.hostName),
            subtitle: Text('Code: ${game.gameCode}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(lobbyControllerProvider.notifier).joinGame(
                  game: game,
                  localPlayerId: localPlayerId,
                  localPlayerName: localPlayerName,
                ),
          ),
        );
      },
    );
  }
}
