import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/auth_repository.dart';

/// Provides the single AuthRepository instance used app-wide.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance);
});

/// Streams the current signed-in user (or null). This is what the router
/// and any "am I logged in" UI should watch — it's the single source of
/// truth for auth state.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Handles the sign-in/sign-up form's submit action and exposes its
/// loading/error state via AsyncValue, so the UI can show a spinner or
/// an error message without extra boolean flags.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial async work needed — this notifier only reacts to calls
    // below (signIn/signUp/signOut).
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithEmail(email, password),
    );
    if (state.hasError) {
      appLogger.e('Sign-in failed: ${state.error}');
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpWithEmail(email, password),
    );
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);
