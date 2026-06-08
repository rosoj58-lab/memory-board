# Memory Board

Memory Board is a portrait-first mobile memory puzzle game. Android is the first target; iOS will use the same Flutter codebase later through Xcode on macOS.

## Stack

- Flutter for shared Android/iOS game UI and logic
- Docker for reproducible Android build tooling and CI-like checks
- GitHub Actions for Android build verification

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
docker compose run --rm flutter flutter test
```

Build an Android APK for a real phone:

```sh
docker compose run --rm flutter flutter build apk
```

The APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
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

Create the remote repository from this folder:

```sh
gh repo create memory-board --public --source=. --remote=origin --push
```

## MVP Direction

The first MVP is one level mode with 30 levels, one board per level, 3 hearts, 1-3 stars, local progress saving, a level 1 tutorial, simple static assets, and basic feedback animations.
