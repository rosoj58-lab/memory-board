import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/app/memory_board_app.dart';
import 'package:memory_board/src/data/progress_repository.dart';
import 'package:memory_board/src/data/settings_repository.dart';
import 'package:memory_board/src/game/game_rules.dart';
import 'package:memory_board/src/game/level_config.dart';
import 'package:memory_board/src/ui/gameplay_screen.dart';

void main() {
  MemoryBoardApp testApp({
    ProgressRepository? progressRepository,
    SettingsRepository? settingsRepository,
  }) {
    return MemoryBoardApp(
      progressRepository: progressRepository ?? InMemoryProgressRepository(),
      settingsRepository: settingsRepository ?? InMemorySettingsRepository(),
    );
  }

  InMemoryProgressRepository repositoryWithCompletedTutorial() {
    return InMemoryProgressRepository(
      const PlayerProgress(
        highestUnlockedLevel: 1,
        bestStarsByLevel: <int, int>{},
        tutorialCompleted: true,
      ),
    );
  }

  InMemoryProgressRepository repositoryWithUnlockedLevels(int level) {
    return InMemoryProgressRepository(
      PlayerProgress(
        highestUnlockedLevel: level,
        bestStarsByLevel: const <int, int>{},
        tutorialCompleted: true,
      ),
    );
  }

  InMemoryProgressRepository repositoryWithProgress(PlayerProgress progress) {
    return InMemoryProgressRepository(progress);
  }

  testWidgets('main menu opens level selection', (tester) async {
    await tester.pumpWidget(testApp());

    expect(find.text('Memory Board'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-progress-summary')), findsOneWidget);
    expect(find.text('Goal 0/90'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Unlocked 1/30'), findsOneWidget);
    expect(find.text('Stars 0/90'), findsOneWidget);
    expect(find.text('Completed 0/30'), findsOneWidget);
    expect(find.text('Next challenge'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Board 3x3'), findsOneWidget);
    expect(find.text('Find 3 sparks'), findsOneWidget);
    expect(find.text('Remember 4s'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('main start and continue open gameplay directly', (tester) async {
    await tester.pumpWidget(testApp());
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-start-button')));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      testApp(progressRepository: repositoryWithUnlockedLevels(4)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu-start-button')));
    await tester.pumpAndSettle();

    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
  });

  testWidgets('next challenge start opens the newest unlocked level',
      (tester) async {
    await tester.pumpWidget(
      testApp(progressRepository: repositoryWithUnlockedLevels(4)),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('Board 4x4'), findsOneWidget);
    expect(find.text('Find 6 sparks'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-challenge-start-button')));
    await tester.pumpAndSettle();

    expect(find.text('Level 4'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
  });

  testWidgets('settings dialog persists the vibration toggle', (tester) async {
    final settingsRepository = InMemorySettingsRepository();
    await tester.pumpWidget(
      testApp(settingsRepository: settingsRepository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-settings-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings-done-button')), findsOneWidget);
    expect(find.text('Vibration'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('haptics-toggle')));
    await tester.pumpAndSettle();

    expect((await settingsRepository.load()).hapticsEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('settings-done-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('menu-settings-button')));
    await tester.pumpAndSettle();

    final switchTile = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('haptics-toggle')),
    );
    expect(switchTile.value, isFalse);
  });

  testWidgets('level selection summary reflects saved progress',
      (tester) async {
    await tester.pumpWidget(
      testApp(
        progressRepository: repositoryWithProgress(
          const PlayerProgress(
            highestUnlockedLevel: 4,
            bestStarsByLevel: <int, int>{1: 3, 2: 2},
            tutorialCompleted: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Unlocked 4/30'), findsOneWidget);
    expect(find.text('Stars 5/90'), findsOneWidget);
    expect(find.text('Completed 2/30'), findsOneWidget);
  });

  testWidgets('level one shows tutorial instruction first', (tester) async {
    await tester.pumpWidget(
      testApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-info-strip')), findsOneWidget);
    expect(find.text('3x3'), findsOneWidget);
    expect(find.text('3 sparks'), findsOneWidget);
    expect(find.text('4s remember'), findsOneWidget);
    expect(find.text('0/3 found'), findsOneWidget);
  });

  testWidgets('locked level cannot be opened', (tester) async {
    await tester.pumpWidget(
      testApp(),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Level 2'), findsNothing);
  });

  testWidgets('reset progress dialog restores the initial state',
      (tester) async {
    final repository = repositoryWithProgress(
      const PlayerProgress(
        highestUnlockedLevel: 3,
        bestStarsByLevel: <int, int>{1: 3, 2: 1},
        tutorialCompleted: true,
      ),
    );
    await tester.pumpWidget(
      testApp(progressRepository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Unlocked 3/30'), findsOneWidget);
    expect(find.text('Stars 4/90'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('levels-settings-button')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('settings-reset-progress-tile')));
    await tester.pumpAndSettle();

    expect(find.text('Reset all progress?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reset-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked 1/30'), findsOneWidget);
    expect(find.text('Stars 0/90'), findsOneWidget);

    final progress = await repository.load();
    expect(progress.highestUnlockedLevel, 1);
    expect(progress.bestStarsByLevel, isEmpty);
    expect(progress.tutorialCompleted, isFalse);
  });

  testWidgets('pause dialog can resume the level', (tester) async {
    await tester.pumpWidget(
      testApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pause-button')));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-resume-button')));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsNothing);
    expect(find.text('Level 1'), findsOneWidget);
  });

  testWidgets('winning level one unlocks next gameplay screen', (tester) async {
    final repository = repositoryWithCompletedTutorial();
    await tester.pumpWidget(
      testApp(progressRepository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);
    for (final target in targets) {
      await tester.tap(find.byKey(ValueKey('board-cell-$target')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Level complete'), findsOneWidget);
    expect(find.byKey(const ValueKey('win-menu-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('win-next-button')), findsOneWidget);
    final titleCenter = tester.getCenter(find.text('Level complete'));
    final starsCenter =
        tester.getCenter(find.byKey(const ValueKey('win-stars-row')));
    final replayCenter =
        tester.getCenter(find.byKey(const ValueKey('win-replay-button')));
    final nextCenter =
        tester.getCenter(find.byKey(const ValueKey('win-next-button')));
    expect((starsCenter.dx - titleCenter.dx).abs(), lessThan(2));
    expect((replayCenter.dx - titleCenter.dx).abs(), lessThan(2));
    expect((nextCenter.dx - titleCenter.dx).abs(), lessThan(2));
    expect(nextCenter.dy, lessThan(replayCenter.dy));

    await tester.tap(find.byKey(const ValueKey('win-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Level 2'), findsOneWidget);
    final progress = await repository.load();
    expect(progress.isLevelUnlocked(2), isTrue);
    expect(progress.starsForLevel(1), 3);
  });

  testWidgets('win dialog can return to the refreshed main menu',
      (tester) async {
    final repository = repositoryWithCompletedTutorial();
    await tester.pumpWidget(
      testApp(progressRepository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);
    for (final target in targets) {
      await tester.tap(find.byKey(ValueKey('board-cell-$target')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('win-menu-button')));
    await tester.pumpAndSettle();

    expect(find.text('Memory Board'), findsOneWidget);
    expect(find.text('Stars 3/90'), findsOneWidget);
    expect(find.text('Unlocked 2/30'), findsOneWidget);
    expect(find.text('Completed 1/30'), findsOneWidget);
  });

  testWidgets('returning to levels highlights the newly unlocked level',
      (tester) async {
    final repository = repositoryWithCompletedTutorial();
    await tester.pumpWidget(
      testApp(progressRepository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);
    for (final target in targets) {
      await tester.tap(find.byKey(ValueKey('board-cell-$target')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('win-levels-button')));
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('level-unlocked-pulse-2')),
      findsOneWidget,
    );
  });

  testWidgets('three wrong taps show the lose dialog', (tester) async {
    await tester.pumpWidget(
      testApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);
    final wrongCells = List.generate(9, (index) => index).where(
      (cell) => !targets.contains(cell),
    );

    for (final cell in wrongCells.take(3)) {
      await tester.tap(find.byKey(ValueKey('board-cell-$cell')));
      await tester.pump(const Duration(milliseconds: 350));
    }

    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const ValueKey('lose-replay-button')), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
  });

  testWidgets('level thirty completes the available MVP levels',
      (tester) async {
    final repository = repositoryWithUnlockedLevels(30);
    await tester.pumpWidget(
      MaterialApp(
        home: GameplayScreen(
          config: buildLevelConfigs().last,
          progressRepository: repository,
          settingsRepository: InMemorySettingsRepository(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Level 30'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-info-strip')), findsOneWidget);
    expect(find.text('6x6'), findsOneWidget);
    expect(find.text('20 sparks'), findsOneWidget);
    expect(find.text('2s remember'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    final targets = generateTargets(level: 30, gridSize: 6, objectCount: 20);
    for (final target in targets) {
      await tester.tap(find.byKey(ValueKey('board-cell-$target')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('All levels complete'), findsOneWidget);
    expect(
      find.text('Congratulations! You completed all available levels.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('win-next-button')), findsNothing);

    final progress = await repository.load();
    expect(progress.highestUnlockedLevel, 30);
    expect(progress.starsForLevel(30), 3);
  });

  testWidgets('level one tutorial appears once and saves completion',
      (tester) async {
    final repository = InMemoryProgressRepository();
    await tester.pumpWidget(
      testApp(progressRepository: repository),
    );

    await tester.tap(find.byKey(const ValueKey('menu-levels-button')));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Remember where the sparks appear. They will hide soon.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-start-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-start-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byKey(const ValueKey('tutorial-recall-prompt')), findsNothing);
    expect(find.byKey(const ValueKey('tutorial-hand-pointer')), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(
        find.byKey(const ValueKey('tutorial-recall-prompt')), findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-hand-pointer')), findsOneWidget);

    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);
    for (final target in targets) {
      await tester.tap(find.byKey(ValueKey('board-cell-$target')));
      await tester.pump(const Duration(milliseconds: 50));
    }

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final progress = await repository.load();
    expect(progress.tutorialCompleted, isTrue);
    expect(progress.isLevelUnlocked(2), isTrue);
  });
}
