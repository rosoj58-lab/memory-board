import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/data/progress_repository.dart';

void main() {
  test('initial progress unlocks only level one', () async {
    final repository = InMemoryProgressRepository();
    final progress = await repository.load();

    expect(progress.highestUnlockedLevel, 1);
    expect(progress.isLevelUnlocked(1), isTrue);
    expect(progress.isLevelUnlocked(2), isFalse);
    expect(progress.tutorialCompleted, isFalse);
  });

  test('complete level unlocks next level and stores best stars', () async {
    final repository = InMemoryProgressRepository();

    var progress = await repository.completeLevel(level: 1, stars: 2);
    expect(progress.highestUnlockedLevel, 2);
    expect(progress.starsForLevel(1), 2);

    progress = await repository.completeLevel(level: 1, stars: 1);
    expect(progress.starsForLevel(1), 2);

    progress = await repository.completeLevel(level: 1, stars: 3);
    expect(progress.starsForLevel(1), 3);
  });

  test('tutorial completed flag can be saved', () async {
    final repository = InMemoryProgressRepository();

    final progress = await repository.markTutorialCompleted();

    expect(progress.tutorialCompleted, isTrue);
  });
}

