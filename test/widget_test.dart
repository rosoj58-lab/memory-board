import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/app/memory_board_app.dart';
import 'package:memory_board/src/data/progress_repository.dart';
import 'package:memory_board/src/game/game_rules.dart';
import 'package:memory_board/src/game/level_config.dart';
import 'package:memory_board/src/ui/gameplay_screen.dart';

void main() {
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

  testWidgets('main menu opens level selection', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: InMemoryProgressRepository()),
    );

    expect(find.text('Memory Board'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('level one shows tutorial instruction first', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('locked level cannot be opened', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: InMemoryProgressRepository()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Level 2'), findsNothing);
  });

  testWidgets('pause dialog can resume the level', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
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
      MemoryBoardApp(progressRepository: repository),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
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
    expect(find.byKey(const ValueKey('win-next-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('win-next-button')));
    await tester.pumpAndSettle();

    expect(find.text('Level 2'), findsOneWidget);
    final progress = await repository.load();
    expect(progress.isLevelUnlocked(2), isTrue);
    expect(progress.starsForLevel(1), 3);
  });

  testWidgets('returning to levels highlights the newly unlocked level',
      (tester) async {
    final repository = repositoryWithCompletedTutorial();
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: repository),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
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
      MemoryBoardApp(progressRepository: repositoryWithCompletedTutorial()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
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
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Level 30'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();

    final targets = generateTargets(level: 30, gridSize: 5, objectCount: 8);
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
      MemoryBoardApp(progressRepository: repository),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Watch where the spirits appear. They will hide soon.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('tutorial-start-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-start-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.byKey(const ValueKey('tutorial-recall-prompt')),
        findsOneWidget);
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
