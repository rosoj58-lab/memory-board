# Memory Board MVP Summary

This is the short product summary. The working build plan is in [mvp-implementation-plan.md](mvp-implementation-plan.md).

## Product

Memory Board is a portrait-first visual memory puzzle for mobile. The player memorizes glowing sparks on a board, waits until they hide, then taps the remembered cells.

The design direction is **Magic Sparks**: friendly dark teal night, mint UI accents, yellow rewards, readable glowing spark objects, and clear level progress.

## Platform

- Android first
- iOS later from the same Flutter codebase
- Portrait orientation only
- Safe-area ready for Android cutouts and future iOS notch/home indicator layouts

## MVP Scope

- Main menu with Start/Continue and Levels actions
- Level selection with completed/current/unlocked/locked states
- Gameplay screen
- Settings popup with vibration and reset progress
- Pause popup
- Win popup
- Lose popup
- Final completion popup
- 30 levels
- 3x3, 4x4, 5x5, and late 6x6 boards
- 3 hearts per level
- 1-3 star rating
- Level 1 tutorial only
- Local progress saving
- Code-native original spark object and simple effects
- Basic animations
- No music or sound effects in MVP
- Vibration/haptics only

Splash screen and app icon are included in the MVP direction, but they should be generated after the final Magic Spark source icon is created. They should not block implementation of the playable game loop.

## Core Loop

1. New player taps Start and enters Level 1 tutorial.
2. Returning player taps Continue and enters the newest unlocked unfinished level.
3. Player can also open Levels and replay any unlocked level.
4. Board appears with visible sparks.
5. Sparks stay visible for the level memorize time.
6. Sparks disappear.
7. Player taps remembered cells.
8. Correct taps reveal sparks and mark cells.
9. Wrong taps mark cells with color and icon feedback, remove hearts, and trigger haptics.
10. Finding all sparks wins the level.
11. Losing all hearts fails the level.
12. Winning unlocks the next level.

## Difficulty

- Levels 1-3: 3x3 board, 3-4 sparks
- Levels 4-10: 4x4 board, 4-6 sparks
- Levels 11-22: 5x5 board, 6-10 sparks
- Levels 23-30: 6x6 board, 8-10 sparks
- Memorize time is fixed at 4s in Room 1

## Stars

- 3 stars: 0 mistakes
- 2 stars: 1 mistake
- 1 star: 2 mistakes
- Fail: 3 mistakes

## Current UX Priorities

1. Make navigation intentional: Start/Continue starts gameplay, Levels opens the level map.
2. Keep reset progress in Settings, not as a risky top-level Levels icon.
3. Make current/next level visually distinct from completed and locked levels.
4. Make result popups reward-forward: Next is primary, Replay is secondary, Menu/Levels are tertiary.
5. Use "Remember/Memorize" wording instead of "Watch".
6. Make the spark object readable as magic/light, not a medical cross.
7. Add small reward animations without slowing gameplay.

## Future Ideas

Future versions can add endless trainer mode, 100 levels, order/sequence memory, object skins, color filtering, hints, sound effects, achievements, daily challenges, and monetization only after the core game feels good.
