# App Boilerplate

A Flutter starting point for a new iOS + Android app: Riverpod for state,
go_router for navigation, Firebase for auth/data. This is deliberately
generic — no game logic lives here. The plan is to build the SET game as
a new `lib/features/sets_game/` folder on top of this once it's running.

## What's in here

```
lib/
  main.dart                 # App entry point: loads .env, inits Firebase, runs the app
  app.dart                  # Root widget: wires theme + router together
  core/
    config/                 # Firebase options (generated per-project, see below)
    theme/                  # Colors, text styles, light/dark ThemeData
    router/                 # go_router setup, including auth-based redirects
    constants/               # Spacing, durations, other app-wide constants
    utils/                  # Logger, etc.
  features/
    auth/                   # Sign in / sign up screen, Firebase Auth wrapper, Riverpod providers
    home/                   # Placeholder landing screen once signed in
    settings/               # Placeholder settings screen (sign out lives here)
  shared/
    widgets/                # Reusable widgets used across features (e.g. AppButton)
test/
  widget_test.dart          # Example test for AppButton
.github/workflows/
  flutter_ci.yml            # Runs `flutter analyze` + `flutter test` on every push/PR
```

The `features/` folder is split by feature, not by screen type — each
feature owns its own `data/` (talks to Firebase/APIs), `domain/` (plain
Dart models/logic), and `presentation/` (screens + Riverpod providers).
When you build SET, it becomes `features/sets_game/` following the same
pattern.

## One-time setup (do this locally — not in this chat)

### 1. Install Flutter

If you haven't already:
https://docs.flutter.dev/get-started/install

Confirm it's working:
```bash
flutter doctor
```
Fix anything it flags (Xcode for iOS, Android Studio/SDK for Android) —
`flutter doctor` tells you exactly what's missing.

### 2. Create the real Flutter project

Flutter projects need native `ios/` and `android/` folders that only
`flutter create` can generate correctly (they contain platform build
config that isn't just plain text). So:

```bash
flutter create --org com.yourdomain app_boilerplate
```

This creates a fresh Flutter project with those native folders already
wired up. Then copy every file from this boilerplate (everything under
`lib/`, `test/`, `.github/`, plus `pubspec.yaml`, `analysis_options.yaml`,
`.gitignore`, `.env.example`) into that new project, overwriting the
default files `flutter create` generated.

> Rename `com.yourdomain` to your actual reverse-domain identifier
> (e.g. `com.shayapps`) — you'll need this again for App Store setup.

### 3. Install dependencies

```bash
cd app_boilerplate
cp .env.example .env
flutter pub get
```

### 4. Set up Firebase

```bash
dart pub global activate flutterfire_cli
firebase login          # opens a browser to sign into your Google account
flutterfire configure   # walks you through picking/creating a Firebase project
```

`flutterfire configure` will:
- ask which platforms to set up (choose iOS + Android)
- overwrite `lib/core/config/firebase_options.dart` with real values
- drop `google-services.json` (Android) and `GoogleService-Info.plist`
  (iOS) into the right native folders automatically

In the Firebase console, also turn on the sign-in methods you want under
**Authentication → Sign-in method** (Email/Password is enabled by
default in this boilerplate's `AuthRepository`).

### 5. Run it

```bash
flutter devices          # confirm a simulator/emulator or device is available
flutter run
```

You should land on a sign-in screen, be able to create an account, and
get redirected to the home screen.

## Everyday commands you'll use

| Command | What it does |
|---|---|
| `flutter run` | Run on a connected device/simulator with hot reload |
| `flutter test` | Run all tests in `test/` |
| `flutter analyze` | Static analysis / lint check |
| `flutter pub add <package>` | Add a new dependency to pubspec.yaml |
| `flutter build apk --release` | Build a release Android APK |
| `flutter build ios --release` | Build a release iOS build (needs Xcode + a Mac) |

## Multiplayer: platform permissions required

Both the Bluetooth and WiFi transport modes need explicit native platform
permissions declared, or they'll silently fail (Bluetooth) or get
rejected by the OS (WiFi local network access on iOS 14+). Add these to
your real Flutter project (they can't live in this boilerplate's `lib/`
folder, since `ios/`/`android/` only exist once you've run `flutter
create` — see the setup steps above).

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect nearby players for multiplayer games.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to host multiplayer games for nearby players.</string>

<!-- Required for WiFi mode's local-network discovery (UDP broadcast) -->
<key>NSLocalNetworkUsageDescription</key>
<string>This app uses your local network to find nearby players for multiplayer games.</string>
<key>NSBonjourServices</key>
<array>
  <string>_setgame._tcp</string>
</array>
```

Also enable these background modes if you want an already-connected BLE
session to survive brief backgrounding (see the design discussion on
reconnect handling): Xcode → Runner target → Signing & Capabilities →
Background Modes → check **Uses Bluetooth LE accessories** and **Acts
as a Bluetooth LE accessory**.

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<!-- Android 12+ (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Android 6-11 needs location permission for BLE scan results -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Android 11 and lower -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- WiFi mode: local network sockets -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
```

The app should call `requestPermissions()` (already wired into
`BleGameTransport`) before scanning, connecting, or advertising — but
these manifest/plist entries are what make the runtime prompts possible
in the first place.

## Multiplayer: what's built vs. what's next

**Built:** the transport-agnostic message protocol
(`domain/multiplayer/game_message.dart`), a `GameTransport` interface
that Bluetooth (real BLE GATT central+peripheral) and WiFi (real TCP/UDP
sockets) both implement, and a working Lobby screen (Host/Join tabs)
that actually starts hosting/discovering/connecting and shows a live
waiting-room list as players join.

**Not yet built:** the actual multiplayer game — right now "Start game"
in the Lobby is a stub. The next step is a host-authoritative game
controller that takes over the connection the Lobby opened
(`lobbyControllerProvider.notifier.activeTransport`), validates
`ClaimAttempt`s from clients, resolves the "simultaneous claim = draw"
rule, and broadcasts `CardsReplaced`/`GameStateSnapshot` — wiring the
message protocol into the actual SET board instead of just the lobby
roster.

## Path to the App Store (high level — we'll go step by step when you're ready)

1. Get an Apple Developer account ($99/yr) and a Google Play Developer
   account ($25 one-time).
2. Set your bundle ID (iOS) / applicationId (Android) to match what you
   used in step 2 above — changing it later is painful.
3. Add a real app icon and splash screen (the `flutter_launcher_icons`
   and `flutter_native_splash` packages automate this from one source
   image).
4. Write a privacy policy — required by both stores, especially once
   Firebase Auth is involved.
5. `flutter build appbundle --release` for Play Store, archive via Xcode
   for the App Store.
6. Fill out store listings (screenshots, description) and submit for
   review.

We can tackle each of these properly when you're ready to ship — for now
this gets you a running, authenticated app shell to build SET on top of.
