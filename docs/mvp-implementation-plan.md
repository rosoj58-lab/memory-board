# Memory Board Realistic MVP Implementation Plan

This is the working implementation plan for the first Android MVP. It defines what we build now, what stays postponed, and how UI/UX decisions should remain consistent while the game grows.

## Product Decision

The MVP is a 30-level portrait mobile game with one core mechanic:

Memorize glowing sparks on a board, wait until they hide, then tap the correct hidden cells.

The visual direction is **Magic Sparks**: bright friendly night, dark teal surfaces, mint controls, yellow spark/reward accents, soft glow, readable rounded tiles, and no copied ghost/reference characters.

The first release should not include endless mode, playable order memory, playable multiple object types, shop, ads, music, leaderboards, cloud saves, or complex asset packs. Those can come later after the basic game loop and navigation feel good on a real phone.

## Current MVP Scope

### Screens

- Main menu
- Level selection
- Gameplay
- Settings dialog
- Pause dialog
- Win dialog
- Lose dialog
- Final completion dialog after level 30

### Navigation Flow

- New player:
  - Main primary CTA: `Start`
  - Action: start Level 1 with tutorial
- Returning player:
  - Main primary CTA: `Continue`
  - Action: start newest unlocked unfinished level
- Secondary main action:
  - `Levels`
  - Action: open Level Selection
- Result popup:
  - Win: `Next` primary, `Replay` secondary, `Levels/Menu` tertiary
  - Lose: `Replay` primary, `Levels/Menu` tertiary
- Reset progress:
  - Lives in Settings with a confirmation dialog
  - Not shown as a dangerous top-level icon on the Levels screen

### Core Gameplay

- Room 1 with 30 configured playable levels
- One board per level
- Levels 1-3: 3x3 board, 3-4 sparks
- Levels 4-10: 4x4 board, 4-6 sparks
- Levels 11-22: 5x5 board, 6-10 sparks
- Levels 23-30: 6x6 board, 8-10 sparks
- Fixed 4s memorize time in Room 1
- Memorization phase with visible sparks
- Recall phase with hidden board
- Correct tap reveals a spark and increments found count
- Wrong tap marks the cell, removes one heart, triggers vibration
- 3 wrong taps fail the level
- Completing all targets wins the level
- Star result:
  - 3 stars for 0 mistakes
  - 2 stars for 1 mistake
  - 1 star for 2 mistakes

### Room Structure

The code now has explicit room and mode configuration:

- `LevelMode.hiddenSet`: implemented Room 1 mode.
- `LevelMode.sequenceTrail`: reserved for Room 2.
- `LevelMode.objectFilter`: reserved for Room 3.

Room 1 is the only playable MVP room:

- Room name: `Magic Glade`
- Levels: 1-30
- Max stars: 90
- Unlock: available from the start

Reserved future rooms:

- Room 2: `Spark Trail`, levels 31-60, unlock target 80 stars, sequence/path memory.
- Room 3: `Moon Garden`, levels 61-90, unlock target 170 stars, object-filter memory.

Future rooms can be visible as locked cards in the level selection UI, but they should not start gameplay until their mechanics are implemented and tested.

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
- Level complete: light impact if available
- Level fail: vibrate

Avoid adding a vibration plugin until we need custom vibration patterns.

## UI/UX Rules

### Safe Areas

- Every screen must be safe-area ready.
- Top controls should have a minimum 44-48 dp hit area.
- Header content should visually sit below the system zone on Android cutouts and future iOS notch/Dynamic Island devices.
- Bottom controls should avoid the future iOS home indicator area.

### Main Menu

- Settings is always a gear icon, not text.
- Primary CTA is contextual:
  - `Start` for a new player
  - `Continue` for a returning player
- Secondary action opens Levels.
- Main progress should feel like journey progress, not only statistics:
  - stars earned
  - completed levels
  - unlocked/current level

### Level Selection

The screen starts with compact room cards:

- Current playable room: Room 1, progress shown as completed levels and stars.
- Locked planned rooms: Room 2 and Room 3, with unlock target copy.

Level tiles must have distinct states:

- Completed:
  - active filled tile
  - star rating visible
- Current/next:
  - highlighted border/glow
  - small `Next` badge
- Unlocked but not completed:
  - active tile, no stars
- Locked:
  - dimmed tile
  - lock icon

Progress and room cards should stay compact enough that level tiles are visible without excessive scrolling on phone screens.

### Gameplay

- Use `Remember/Memorize` wording, not `Watch`.
- Room 1 should keep integer timing only: `4s remember`.
- Found counter should be clear, for example `2/4 found`.
- Correct and wrong states must not rely only on color:
  - correct: spark reveal + glow
  - wrong: red state + X + shake
- Hearts should have readable full/lost states.
- Tutorial pointer appears only after inactivity in recall phase.

### Result Popups

- Background behind result popups should be strongly dimmed enough that the popup owns focus.
- Popups should not close on outside tap.
- Win hierarchy:
  - title
  - stars/reward
  - `Next` as primary action
  - `Replay` as secondary action
  - `Levels` and `Menu` as tertiary text/icon actions
- Lose hierarchy:
  - title
  - message
  - `Replay` as primary action
  - `Levels` and `Menu` as tertiary actions

## Visual Direction

### Theme

Use **Magic Sparks**:

- Dark teal/night background
- Mint and turquoise UI accents
- Yellow/gold sparks and rewards
- Soft glow effects
- Rounded board tiles
- Minimal, readable detail
- Friendly magical tone, not horror

### Core Palette

- Background primary: `#061F22`
- Background secondary: `#0B2D32`
- Card/surface: `#103A42`
- Card border: `#1E5960`
- Tile default: `#0E3036`
- Tile active: `#15535B`
- Primary button: `#88E3D0`
- Primary button text: `#063135`
- Accent/spark: `#FFD86B`
- Success: `#55E6A5`
- Error: `#FF6B78`
- Text primary: `#F2FFFC`
- Text secondary: `#A9C8C4`
- Disabled: `#536A68`

### Spark Object

The object must not look like:

- a medical cross
- a ghost from the reference
- a generic plus icon

Recommended MVP spark:

- 4-point or 6-point rounded asymmetric spark
- glowing circular center
- 1-2 small particles near the main form
- main color `#FFD86B`
- inner highlight `#FFF7C2`
- secondary glow `#88E3D0`
- particle color `#EFFFFA`

Animation goals:

- idle pulse during memorization phase
- fade when memorization ends
- bounce + glow when correctly selected

Future object skins can include Firefly, Memory Orb, Star Seed, Moon Drop, and Rune Pebble, but MVP uses only Magic Spark.

## Asset Plan

### Use Code-Native UI First

These do not need external assets:

- Spark object: Flutter `CustomPainter`
- Hearts: Flutter/Material icon
- Stars: Flutter/Material icon
- Pause/play/replay/next/home/settings: Flutter/Material icons
- Empty/correct/wrong tiles: Flutter widget styles
- Glow, shake, bounce: Flutter animations
- Basic particles: Flutter custom painter or lightweight widget particles

### Original Assets To Create

Create these as original assets for the MVP asset pass:

- App icon: 1024x1024 PNG, dark teal background with one readable Magic Spark
- Splash logo: transparent PNG, compatible with Android 12 splash constraints
- Optional simple background illustration layer

Preferred approach: generate or draw original bitmap assets, then store them under `assets/images/` with a small `assets/ATTRIBUTION.md`.

### External Asset Fallbacks

If generated assets are not good enough, use only license-safe sources:

- Kenney assets as first fallback because Kenney states its game assets are CC0/public domain and attribution is not required.
- Game-icons.net only if needed, because it is CC BY and requires attribution.

No random assets from Google Images, Pinterest, App Store screenshots, or other games.

## Animation Plan

Use Flutter implicit animations first. They are enough for MVP and keep the code maintainable.

### Required

- Spark appear: scale 0.85 to 1.0 plus fade
- Spark disappear: fade out
- Correct tap: glow plus small bounce
- Wrong tap: red state plus short shake
- Heart loss: shrink/fade
- Win dialog: stars appear one by one
- Level unlock/current level: small pulse on next level tile
- Primary result CTA: subtle pulse

### Optional If Time Allows

- Small particle burst on win
- Spark float upward before disappearing
- Stronger board dim overlay on fail
- Animated background particles

No Rive/Lottie in MVP unless static Flutter animations are not enough. Rive is powerful, but it adds a separate animation-authoring workflow that is not needed for this first game.

## Library Decisions

### Use

- `shared_preferences`: local progress, stars, tutorial flag
- `flutter_svg`: render original SVG assets if we choose SVG for future assets
- `flutter_launcher_icons`: generate Android/iOS launcher icons from one source image
- `flutter_native_splash`: generate native Android/iOS/web splash screens
- Flutter widget tests: app-level checks for menu, level start, win/fail paths

### Avoid For MVP

- Flame: not needed because the game is UI-grid based, not physics/sprite-loop heavy
- Rive/Lottie: not needed for the first animation pass
- Audio packages: sound is intentionally out of MVP
- Ads/analytics/crash reporting: postponed until the game is worth distributing more broadly

## Implementation Milestones

### Milestone 1: Stable Game Foundation

Status: implemented.

- Flutter project foundation
- Android/web/iOS platform generation path
- Docker and GitHub Actions Android build
- Level config model
- Progress repository using `shared_preferences`
- Route/navigation structure
- Portrait lock and safe-area layout
- Tests for level config and star logic

### Milestone 2: Real Gameplay Loop

Status: implemented.

- Memorization timer
- Recall state
- Correct/wrong cell states
- Hearts and fail state
- Win state and star calculation
- Vibration feedback
- Replay, next, levels, menu actions

### Milestone 3: Tutorial and Difficulty Pass

Status: implemented and still balancing.

- Level 1 tutorial overlay
- Delayed animated pointer after recall inactivity
- Tutorial completion persistence
- 30-level Room 1 table with easier, human-feasible progression
- Level selection star display

### Milestone 3.5: Room Foundation

Status: implemented as non-playable structure.

- `RoomConfig` added
- `LevelMode` added
- Room 1 maps to the current 30 hidden-set levels
- Room 2 is reserved for sequence trail gameplay
- Room 3 is reserved for object-filter gameplay
- Level selection shows compact room cards
- Progress exposes total stars and room-range stats

### Milestone 4: UI/UX Foundation Pass

Status: active.

- Main menu Start/Continue + Levels flow
- Settings gear consistency
- Reset progress moved to Settings
- Safer result popup hierarchy
- Current/next level tile state
- `Remember/Memorize` wording
- Stronger safe-area and hit-area rules

Exit criteria:

- Main menu starts the correct next gameplay screen
- Level selection remains available as secondary navigation
- No top-level reset icon on Levels
- Result popup primary action is unambiguous
- Current/next level is visually obvious

### Milestone 5: Visual MVP Pass

Status: active.

- Replace plus-like object with readable Magic Spark
- Keep dark teal/mint/yellow palette consistent
- Add original app icon and splash source
- Generate launcher icons
- Generate native splash
- Add simple background treatment

Exit criteria:

- The app no longer feels like a Flutter demo
- The main object reads as spark/light, not medical/ghost
- All included assets are original or license-safe
- `assets/ATTRIBUTION.md` documents any third-party assets

### Milestone 6: Animation and Reward Pass

Status: active.

- Add sequential star reveal: implemented
- Add small win particles: implemented
- Add Next button pulse in win popup
- Improve heart loss animation: implemented with shake, burst, and clearer broken-heart state
- Add subtle logo/background motion

Exit criteria:

- Victory feels rewarding
- Feedback is clear on a phone screen
- Animations do not slow gameplay
- No important UI shifts during animations

### Milestone 7: Phone Testing and APK Delivery

Status: repeated after each meaningful UI/gameplay change.

- Build debug APK in GitHub Actions
- Download APK artifact locally
- Install on Android phone
- Test small and large phone layouts
- Test rotation behavior
- Test safe areas/cutouts as much as available
- Run widget tests

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
  - Target generation count and uniqueness
  - Progress persistence/reset

- Widget tests:
  - Main menu Start/Continue and Levels actions
  - Settings persists vibration toggle and can reset progress
  - Level starts in memorization phase
  - Correct tap updates progress
  - Wrong tap removes heart
  - Win dialog appears and navigates correctly
  - Lose dialog appears and navigates correctly
  - Tutorial appears once and delayed hint timing works

### Manual

- Install APK on Android phone
- Play levels 1, 2, 7, 10, 14, 23, and 30
- Check board fit on 3x3, 4x4, 5x5, and 6x6
- Check one-handed tap comfort
- Check haptic feedback is not annoying
- Check dialogs and navigation
- Check that reset progress is hard to trigger accidentally

### Codex Click-Through Testing

Use Flutter web preview for quick visual and click-through checks:

- Build web
- Run a local web server
- Inspect screens with browser tooling
- Click Start/Continue, Levels, settings, gameplay, result dialogs
- Use screenshots to catch overlap, clipped text, and layout problems

Android phone testing still remains required because haptics, APK install, and true mobile sizing cannot be fully trusted from web preview.

## Backlog

### P0

- Main CTA: Start/Continue starts gameplay
- Secondary Levels action on main
- Settings gear on main
- Reset progress moved into Settings
- Current/next level tile state
- Result popup action hierarchy
- Replace plus-like spark with stronger Magic Spark
- Rename Watch to Remember/Memorize

### P1

- Stronger progress presentation
- Room unlock flow when Room 2 becomes playable
- Sequential star reveal
- Win particles
- Stronger popup dim
- Compact level cards

### P2

- Animated logo/background particles
- App icon and splash final art pass
- Additional object skins
- Future playable level packs and unlock thresholds

## What Is Explicitly Out Of MVP

- Music
- Sound effects
- Endless trainer mode
- Score mode
- Playable Room 2 sequence memory
- Playable Room 3 color/type filtering
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
- Flutter widget tests: https://docs.flutter.dev/testing
- Kenney asset license note: https://kenney.nl/support
