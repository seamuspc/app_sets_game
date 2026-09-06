/// App-wide constant values. Keep this free of anything environment-specific
/// (those belong in .env / EnvConfig) — this is for things that never change
/// between builds, like route names and durations.
class AppConstants {
  AppConstants._();

  static const String appName = 'App Boilerplate';

  // Standard animation durations, so transitions feel consistent everywhere.
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Standard spacing scale — use these instead of magic numbers in padding.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
}
