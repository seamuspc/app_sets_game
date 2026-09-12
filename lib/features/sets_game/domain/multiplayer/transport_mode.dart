/// The three ways two devices can connect for a multiplayer game.
enum TransportMode { bluetooth, wifi, internet }

extension TransportModeX on TransportMode {
  String get label => switch (this) {
        TransportMode.bluetooth => 'Bluetooth',
        TransportMode.wifi => 'WiFi',
        TransportMode.internet => 'Internet',
      };

  /// A short caveat shown next to the mode, since each has a real
  /// constraint worth surfacing before someone tries to use it.
  String get caveat => switch (this) {
        TransportMode.bluetooth =>
          'Both players must have the app open (background use is limited)',
        TransportMode.wifi => 'Both devices must be on the same WiFi network',
        TransportMode.internet => 'Coming soon',
      };

  bool get isAvailable => this != TransportMode.internet;
}
