import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/multiplayer/transport_mode.dart';

/// Holds the selected transport mode (Bluetooth/WiFi/Internet), chosen
/// on the Settings screen per the earlier design decision — the Lobby
/// screen reads this but doesn't let the player change it directly.
class TransportModeController extends Notifier<TransportMode> {
  @override
  TransportMode build() => TransportMode.wifi; // safest default: no
  // third-party plugin, works on every device/simulator.

  void select(TransportMode mode) => state = mode;
}

final transportModeControllerProvider =
    NotifierProvider<TransportModeController, TransportMode>(
  TransportModeController.new,
);
