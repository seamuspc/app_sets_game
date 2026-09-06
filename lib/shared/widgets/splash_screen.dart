import 'package:flutter/material.dart';

/// Shown briefly on cold start while Firebase resolves whether there's
/// an existing signed-in session. Without this, the screen is blank
/// white for that moment instead of showing something — which makes it
/// hard to tell "still loading" apart from "actually broken".
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}