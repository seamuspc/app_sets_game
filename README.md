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
