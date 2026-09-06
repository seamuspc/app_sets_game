import 'package:flutter/material.dart';

/// A primary button that shows a spinner instead of its label while
/// `isLoading` is true, and disables itself so users can't double-submit.
/// Use this anywhere you'd reach for ElevatedButton + a manual loading
/// boolean — it saves rewriting that pattern per-screen.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color.fromARGB(255, 65, 48, 48),
              ),
            )
          : Text(label),
    );
  }
}
