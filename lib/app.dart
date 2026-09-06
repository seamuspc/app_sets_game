import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'shared/widgets/splash_screen.dart';

/// The root widget of the app.
///
/// This is a ConsumerWidget (a Riverpod-aware widget) so it can watch
/// providers directly — here, the router provider — without needing a
/// separate wrapper widget.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'App Boilerplate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      // While Firebase is resolving whether there's an existing signed-in
      // session (cold start only — usually well under a second), show a
      // spinner instead of a blank frame. Once authState has a value,
      // this just returns the router's normal page as-is.
      builder: (context, child) {
        if (authState.isLoading) {
          return const SplashScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}