import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/sets_game/presentation/screens/lobby_screen.dart';
import '../../features/sets_game/presentation/screens/sets_game_screen.dart';

/// Route path constants — reference these instead of typing raw strings,
/// so a typo becomes a compile error instead of a silent broken nav.
class AppRoutes {
  AppRoutes._();

  static const signIn = '/sign-in';
  static const home = '/';
  static const settings = '/settings';
  static const game = '/game';
  static const lobby = '/lobby';
}

/// Set this to false at any time to re-enable the sign-in gate while
/// still in debug mode. This flag has NO effect on release builds
/// (kDebugMode is always false there) — it can never accidentally ship
/// with auth disabled.
const bool skipAuthGateInDebug = true;

/// The app's router, exposed as a Riverpod provider so it can react to
/// auth state changes (see `redirect` below) without manual listeners.
final appRouterProvider = Provider<GoRouter>((ref) {
  // `authStateProvider` is a stream provider — watching it here means the
  // router rebuilds and re-evaluates redirects whenever sign-in state
  // changes, e.g. after a successful login or a sign-out.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (kDebugMode && skipAuthGateInDebug) return null;

      // Still waiting on Firebase's first auth event (e.g. cold start) —
      // don't redirect yet, or you'll flash the sign-in screen every launch.
      if (authState.isLoading) return null;

      final isSignedIn = authState.value != null;
      final isGoingToSignIn = state.matchedLocation == AppRoutes.signIn;

      // Not signed in and not already heading to sign-in -> redirect there.
      if (!isSignedIn && !isGoingToSignIn) {
        return AppRoutes.signIn;
      }
      // Signed in but sitting on the sign-in screen -> bounce to home.
      if (isSignedIn && isGoingToSignIn) {
        return AppRoutes.home;
      }
      // No redirect needed.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.game,
        builder: (context, state) => const SetsGameScreen(),
      ),
      GoRoute(
        path: AppRoutes.lobby,
        builder: (context, state) => const LobbyScreen(),
      ),
    ],
  );
});
