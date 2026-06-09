# Memory Board

Memory Board is a portrait-first mobile memory puzzle game. Android is the first target; iOS will use the same Flutter codebase later through Xcode on macOS.

## Stack

- Flutter for shared Android/iOS game UI and logic
- Docker for reproducible Android build tooling and CI-like checks
- GitHub Actions for Android build verification

## Local Flutter Commands

Flutter is expected in `PATH`. On this Mac it can be used from:

```sh
export PATH="/Users/irinawork/development/flutter/bin:$PATH"
```

Run local checks:

```sh
flutter pub get
flutter analyze
flutter test
flutter build web
```

Run a browser preview for Codex click-through testing:

```sh
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Then open:

```text
http://127.0.0.1:8080
```

## Local Docker Commands

Build the Flutter tooling container:

```sh
docker compose build flutter
```

Create or repair Flutter platform files:

```sh
docker compose run --rm flutter flutter create --platforms=android,ios,web --org com.irina.memoryboard --project-name memory_board .
```

Run checks:

```sh
docker compose run --rm flutter flutter pub get
docker compose run --rm flutter flutter analyze
docker compose run --rm flutter flutter test
```

Build an Android APK for a real phone:

```sh
docker compose run --rm flutter flutter build apk --debug
```

The APK will be available at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

For development testing, the app can also run as a Flutter web build so Codex can inspect screens and click through them with browser tooling:

```sh
docker compose run --rm --service-ports flutter flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Then open:

```text
http://localhost:8080
```

## GitHub

The project is pushed to:

```text
https://github.com/rosoj58-lab/memory-board
```

The Android workflow runs on every push to `main`. It verifies the app and uploads a debug APK artifact.

Download the latest successful APK artifact:

```sh
scripts/download_android_apk.sh
```

The downloaded APK is written to:

```text
artifacts/memory-board-debug-apk/app-debug.apk
```

Install it on a connected Android phone with `adb`:

```sh
scripts/install_android_debug_apk.sh
```

## MVP Direction

The first MVP is a Magic Sparks memory game with 30 levels, one board per level, 3 hearts, 1-3 stars, local progress saving, a level 1 tutorial, code-native original spark visuals, haptics, and basic feedback animations.

Current UX direction:

- New player taps `Start` and enters Level 1 tutorial.
- Returning player taps `Continue` and enters the newest unlocked unfinished level.
- `Levels` opens the level selection screen for replaying unlocked levels.
- Settings contains vibration and reset progress.
- No music or sound effects in MVP.

Detailed implementation plan:

```text
docs/mvp-implementation-plan.md
```

## Phone Test Checklist

- Install the debug APK on Android.
- Play levels 1, 2, 7, 10, 14, 23, and 30.
- Check that 3x3, 4x4, 5x5, and 6x6 boards fit without clipped UI.
- Check that haptics feel useful and not annoying.
- Confirm the tutorial appears once, progress persists, settings reset is confirmed, and level 30 ends with the final completion dialog.
