import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/data/progress_repository.dart';
import 'package:memory_board/src/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('progress exposes totals and room ranges', () async {
    final repository = InMemoryProgressRepository();

    await repository.completeLevel(level: 1, stars: 3);
    await repository.completeLevel(level: 2, stars: 2);
    final progress = await repository.completeLevel(level: 3, stars: 1);

    expect(progress.totalStars, 6);
    expect(progress.completedLevelCount, 3);
    expect(progress.starsInRange(1, 30), 6);
    expect(progress.completedInRange(1, 30), 3);
    expect(progress.starsInRange(31, 60), 0);
    expect(progress.completedInRange(31, 60), 0);
  });

  test('room two stays locked until eighty stars', () async {
    final repository = InMemoryProgressRepository();

    PlayerProgress progress = await repository.load();
    for (var level = 1; level <= 30; level += 1) {
      progress = await repository.completeLevel(level: level, stars: 1);
    }

    expect(progress.totalStars, 30);
    expect(progress.highestUnlockedLevel, 30);
    expect(progress.isLevelUnlocked(31), isFalse);
  });

  test('room two unlocks after improving room one to eighty stars', () async {
    final repository = InMemoryProgressRepository();

    for (var level = 1; level <= 30; level += 1) {
      await repository.completeLevel(level: level, stars: 1);
    }
    PlayerProgress progress = await repository.load();
    expect(progress.highestUnlockedLevel, 30);

    for (var level = 1; level <= 25; level += 1) {
      progress = await repository.completeLevel(level: level, stars: 3);
    }
    progress = await repository.completeLevel(level: 26, stars: 2);

    expect(progress.totalStars, 81);
    expect(progress.highestUnlockedLevel, 31);
    expect(progress.isLevelUnlocked(31), isTrue);
  });

  test('tutorial completed flag can be saved', () async {
    final repository = InMemoryProgressRepository();

    final progress = await repository.markTutorialCompleted();

    expect(progress.tutorialCompleted, isTrue);
  });

  test('in-memory progress can be reset', () async {
    final repository = InMemoryProgressRepository();
    await repository.completeLevel(level: 1, stars: 3);
    await repository.markTutorialCompleted();

    final progress = await repository.reset();

    expect(progress.highestUnlockedLevel, 1);
    expect(progress.bestStarsByLevel, isEmpty);
    expect(progress.tutorialCompleted, isFalse);
  });

  test('preferences repository persists progress across instances', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    var repository = PreferencesProgressRepository(preferences);
    await repository.completeLevel(level: 1, stars: 2);
    await repository.completeLevel(level: 1, stars: 1);
    await repository.markTutorialCompleted();

    repository = PreferencesProgressRepository(preferences);
    final progress = await repository.load();

    expect(progress.highestUnlockedLevel, 2);
    expect(progress.starsForLevel(1), 2);
    expect(progress.tutorialCompleted, isTrue);
  });

  test('preferences repository reset clears stored progress', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    var repository = PreferencesProgressRepository(preferences);
    await repository.completeLevel(level: 1, stars: 3);
    await repository.markTutorialCompleted();
    await repository.reset();

    repository = PreferencesProgressRepository(preferences);
    final progress = await repository.load();

    expect(progress.highestUnlockedLevel, 1);
    expect(progress.bestStarsByLevel, isEmpty);
    expect(progress.tutorialCompleted, isFalse);
  });

  test('initial settings enable haptics', () async {
    final repository = InMemorySettingsRepository();
    final settings = await repository.load();

    expect(settings.hapticsEnabled, isTrue);
  });

  test('in-memory settings can disable haptics', () async {
    final repository = InMemorySettingsRepository();

    final settings = await repository.setHapticsEnabled(false);

    expect(settings.hapticsEnabled, isFalse);
    expect((await repository.load()).hapticsEnabled, isFalse);
  });

  test('preferences settings persist haptics toggle', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();

    var repository = PreferencesSettingsRepository(preferences);
    await repository.setHapticsEnabled(false);

    repository = PreferencesSettingsRepository(preferences);
    final settings = await repository.load();

    expect(settings.hapticsEnabled, isFalse);
  });
}
