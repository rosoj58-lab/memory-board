# Memory Board MVP Summary

This is the short product summary. The working build plan is in [mvp-implementation-plan.md](mvp-implementation-plan.md).

## Product

Memory Board is a simple visual memory puzzle for mobile. The player sees objects on a grid, memorizes their positions, waits for them to disappear, then taps the hidden cells from memory.

## Platform

- Android first
- iOS later from the same Flutter codebase
- Portrait orientation only
- Safe-area ready for Android cutouts and future iOS notch/home indicator layouts

## MVP Scope

- Main menu
- Level selection
- Gameplay screen
- Pause popup
- Win popup
- Lose popup
- Final completion popup
- 30 levels
- 3x3, 4x4, and 5x5 boards
- 3 hearts per level
- 1-3 star rating
- Level 1 tutorial only
- Local progress saving
- Simple original or license-safe static assets
- Basic animations
- No music or sound effects in MVP
- Vibration/haptics only

Splash screen and app icon are included in the MVP, but they should be generated after the first original logo/icon asset is created. They should not block implementation of the playable game loop.

## Core Loop

1. Player selects an unlocked level.
2. Board appears with several visible objects.
3. Objects stay visible for the level show time.
4. Objects disappear.
5. Player taps remembered cells.
6. Correct taps reveal and mark cells.
7. Wrong taps mark cells and remove hearts.
8. Finding all objects wins the level.
9. Losing all hearts fails the level.
10. Winning unlocks the next level.

## Difficulty

- Levels 1-8: 3x3 board
- Levels 9-22: 4x4 board
- Levels 23-30: 5x5 board
- Object count grows from 3 to 8
- Show time gradually decreases from about 4.0s to 2.5s
- Do not exceed 8 objects in MVP

## Stars

- 3 stars: 0 mistakes
- 2 stars: 1 mistake
- 1 star: 2 mistakes
- Fail: 3 mistakes

## Future Ideas

Future versions can add endless trainer mode, 100 levels, order/sequence memory, object type filtering, color filtering, hints, sound effects, achievements, and daily challenges.
