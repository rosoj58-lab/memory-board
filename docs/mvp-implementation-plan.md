# Memory Board Realistic MVP Implementation Plan

This document is the working implementation plan for the first Android MVP. It replaces the broader idea document when we need to decide what to build now, what to postpone, and how each feature will be implemented.

## Executive Decision

The MVP remains a 30-level portrait mobile game with one core mechanic:

Remember highlighted cells, wait until they disappear, then tap the correct hidden cells.

The first release should not try to include endless mode, score mode, order memory, color/type filtering, 100 levels, shop, ads, music, leaderboards, or complex asset sets. Those are good future ideas, but they would slow down the first playable build and create too many balancing and UI problems before the base game is proven.

## Critique of the Original MVP

The original plan is directionally good, but too optimistic in three areas:

1. Asset scope is too large for the first build.
   A full set of original app icon, splash logo, menu background, gameplay background, empty tile, visible tile, correct tile, wrong tile, ghost object, hearts, stars, buttons, particles, and tutorial hand can be done, but not all should block the first playable MVP. Many UI assets can be implemented with Flutter widgets and icons first, then replaced with custom art.

2. Animation scope needs priority.
   Cell reveal, wrong tap feedback, heart loss, and win stars are worth doing now. Decorative particles and highly polished object fly-away animation are nice, but should be simple and bounded.

3. Tutorial should be smaller.
   A multi-step guided hand tutorial is useful, but for MVP it should be a short Level 1 overlay plus one animated pointer. It should not become a separate tutorial engine.

## MVP Scope That I Will Implement

### Screens

- Main menu
- Level selection
- Gameplay
- Pause dialog
- Win dialog
- Lose dialog
- Final completion dialog after level 30

Splash and launcher icon are included, but generated through tooling after the first original icon/splash asset is created.

### Core Gameplay

- 30 configured levels
- One board per level
- 3x3 board for levels 1-8
- 4x4 board for levels 9-22
- 5x5 board for levels 23-30
- 3 to 8 objects per level
- Memorization phase with visible objects
- Recall phase with hidden board
- Correct tap reveals object and increments progress
- Wrong tap marks cell, removes one heart, triggers vibration
- 3 wrong taps fail the level
- Completing all targets wins the level
- Star result:
  - 3 stars for 0 mistakes
  - 2 stars for 1 mistake
  - 1 star for 2 mistakes

### Progress

- Highest unlocked level
- Best star count per completed level
- Tutorial completed flag
- Saved locally on device

Implementation: `shared_preferences`, because MVP persistence is simple key-value data. The package is maintained by `flutter.dev`, supports Android and iOS, and is designed for reading/writing simple key-value pairs.

### Vibration

No sounds in MVP.

Use Flutter's built-in `HapticFeedback`:

- Correct tap: light selection/click feedback
- Wrong tap: stronger vibration feedback
- Level complete: success-style feedback if available, otherwise simple vibrate
- Level fail: vibrate

Implementation note: use Flutter platform haptics first. Avoid adding a vibration plugin until we need custom vibration patterns.

### Portrait and Safe Areas

- Lock phone layout to portrait in Flutter with `SystemChrome.setPreferredOrientations`.
- Also set Android manifest orientation when platform files are present.
- Wrap screens in `SafeArea`.
- Use responsive board sizing:
  - Board width: up to 92% of screen width
  - Board max size constrained so HUD and bottom area remain visible
  - Cell tap target should stay close to or above 48 dp

Important nuance: current Flutter docs note that Android 16/API 36 can restrict orientation locking on devices with display width >= 600 dp. The game should still lay out correctly if a tablet ignores the lock.

## Visual Direction

The visual style remains cute spooky, but the first implementation will be controlled:

- Dark teal/night background
- Soft glowing board cells
- One friendly spirit/ghost-like object
- Material icons for hearts, stars, pause, replay, next, home
- Custom original app icon and splash image later in the asset pass

This keeps the game visually coherent without requiring a large custom art pipeline before the mechanics are stable.

## Asset Plan

### Use Code-Native UI First

These do not need external assets:

- Hearts: Flutter/Material icon
- Stars: Flutter/Material icon
- Pause/play/replay/next/home: Flutter/Material icons
- Empty/correct/wrong tiles: Flutter widget styles
- Glow, shake, bounce: Flutter animations
- Basic particles: Flutter custom painter or lightweight widget particles

### Original Assets To Create

Create these as original assets for the MVP:

- App icon: 1024x1024 PNG, readable at small size
- Splash logo: transparent PNG, compatible with Android 12 splash constraints
- Spirit object: SVG or transparent PNG
- Tutorial hand pointer: SVG or transparent PNG
- Optional simple background texture/illustration

Preferred approach: generate original bitmap assets, then cleanly store them under `assets/images/` with a small `assets/ATTRIBUTION.md`.

### External Asset Fallbacks

If generated assets are not good enough, use only license-safe sources:

- Kenney assets as first fallback because Kenney states its game assets are CC0/public domain and attribution is not required.
- Game-icons.net only if needed, because it is CC BY and requires attribution. That is acceptable but creates attribution work, so it is not the first choice.

No random assets from Google Images, Pinterest, App Store screenshots, or other games.

## Animation Plan

Use Flutter implicit animations first. They are enough for MVP and keep the code maintainable.

### Required

- Object appear: scale 0.85 to 1.0 plus fade
- Object disappear: fade out
- Correct tap: glow plus small bounce
- Wrong tap: red state plus short shake
- Heart loss: shrink/fade
- Win dialog: stars appear one by one
- Level unlock: small pulse on next level tile

### Optional If Time Allows

- Small particle burst on win
- Object float upward before disappearing
- Board dim overlay on fail

No Rive/Lottie in MVP unless static Flutter animations are not enough. Rive is powerful, but it adds a separate animation-authoring workflow that is not needed for this first game.

## Library Decisions

### Use

- `shared_preferences`: local progress, stars, tutorial flag
- `flutter_svg`: render original SVG assets if we choose SVG for spirit/hand/icons
- `flutter_launcher_icons`: generate Android/iOS launcher icons from one source image
- `flutter_native_splash`: generate native Android/iOS/web splash screens
- Flutter `integration_test`: app-level tests for menu, level start, win/fail path

### Avoid For MVP

- Flame: not needed because the game is UI-grid based, not physics/sprite-loop heavy
- Rive/Lottie: not needed for the first animation pass
- Audio packages: sound is intentionally out of MVP
- Ads/analytics/crash reporting: postponed until the game is worth distributing more broadly

## Implementation Milestones

### Milestone 1: Stable Game Foundation

- Split current single-file prototype into feature folders
- Add level config model
- Add game state model
- Add progress repository using `shared_preferences`
- Add route/navigation structure
- Add portrait lock and safe-area layout
- Add tests for level config and star logic

Exit criteria:

- App opens to menu
- Level selection shows 30 levels
- Locked/unlocked state works
- Progress persists after restart
- CI passes

### Milestone 2: Real Gameplay Loop

- Implement memorization timer
- Implement recall state
- Implement correct/wrong cell states
- Implement hearts and fail state
- Implement win state and star calculation
- Add vibration feedback
- Add replay, next, home actions

Exit criteria:

- A player can complete and fail levels 1-30
- Wrong taps cannot be repeated for extra heart loss
- Correct cells cannot be double-counted
- Next level unlocks only after win
- CI builds APK

### Milestone 3: Tutorial and UX Polish

- Add Level 1 tutorial overlay
- Add animated hand pointer for one guided tap
- Ensure tutorial does not repeat after completion
- Add pause dialog
- Add final completion dialog after level 30
- Improve level selection star display

Exit criteria:

- First-time player understands the mechanic without external explanation
- Tutorial flag is saved locally
- Dialog buttons behave correctly

### Milestone 4: Visual MVP Pass

- Add final dark teal/cute spooky theme
- Add original spirit object asset
- Add original app icon and splash image
- Generate launcher icons
- Generate native splash
- Add simple background treatment
- Replace placeholder object icon

Exit criteria:

- The app no longer feels like a Flutter demo
- All included assets are original or license-safe
- `assets/ATTRIBUTION.md` documents any third-party assets

### Milestone 5: Animation and Feedback Pass

- Add fade/scale object appear and disappear
- Add correct tap bounce/glow
- Add wrong tap shake
- Add heart loss animation
- Add sequential star reveal
- Add simple win particles if implementation stays small

Exit criteria:

- Feedback is clear on a phone screen
- Animations do not make gameplay feel slow
- No important UI shifts during animations

### Milestone 6: Phone Testing and APK Delivery

- Build debug APK in GitHub Actions
- Download APK artifact locally
- Install on Android phone
- Test small and large phone layouts
- Test rotation behavior
- Test safe areas/cutouts as much as available
- Run widget/integration tests

Exit criteria:

- APK installs on a real Android phone
- A full level can be played by hand
- No obvious overlap, clipping, or tiny tap targets
- CI is green on `main`

## Testing Plan

### Automated

- Unit tests:
  - Level progression table
  - Star calculation
  - Heart loss
  - Target generation count and uniqueness

- Widget tests:
  - Main menu opens level selection
  - Level starts in memorization phase
  - Correct tap updates progress
  - Wrong tap removes heart
  - Win dialog appears
  - Lose dialog appears

- Integration tests:
  - First-launch tutorial path
  - Win level 1 and unlock level 2
  - Restart app and verify progress remains

### Manual

- Install APK on Android phone
- Play levels 1, 8, 9, 22, 23, 30
- Check board fit on 3x3, 4x4, 5x5
- Check one-handed tap comfort
- Check haptic feedback is not annoying
- Check dialogs and navigation

### Codex Click-Through Testing

Use Flutter web preview for quick visual and click-through checks:

- Run web server locally through Docker or CI environment
- Inspect screens with browser tooling
- Click Play, select level, tap board cells, verify dialogs
- Use screenshots to catch overlap, clipped text, and layout problems

Android phone testing still remains required because haptics, APK install, and true mobile sizing cannot be fully trusted from web preview.

## What Is Explicitly Out Of MVP

- Music
- Sound effects
- Endless trainer mode
- Score mode
- 100 levels
- Order/sequence memory
- Color/type filtering
- Multiple boards inside one level
- Hint economy
- Shop
- Ads
- Monetization
- Leaderboards
- Cloud saves
- Account system
- Daily challenges
- Achievements

## Source Notes

- Flutter `shared_preferences`: https://pub.dev/packages/shared_preferences
- Flutter SVG rendering: https://pub.dev/packages/flutter_svg
- Flutter launcher icon generation: https://pub.dev/packages/flutter_launcher_icons
- Flutter native splash generation: https://pub.dev/packages/flutter_native_splash
- Flutter haptics: https://api.flutter.dev/flutter/services/HapticFeedback/vibrate.html
- Flutter orientation locking: https://api.flutter.dev/flutter/services/SystemChrome/setPreferredOrientations.html
- Flutter implicit animations: https://docs.flutter.dev/learn/pathway/tutorial/implicit-animations
- Flutter integration tests: https://docs.flutter.dev/testing/integration-tests
- Kenney asset license note: https://kenney.nl/support

