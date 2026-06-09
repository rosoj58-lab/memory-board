import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/level_config.dart';

class PlayerProgress {
  const PlayerProgress({
    required this.highestUnlockedLevel,
    required this.bestStarsByLevel,
    required this.tutorialCompleted,
  });

  factory PlayerProgress.initial() {
    return const PlayerProgress(
      highestUnlockedLevel: 1,
      bestStarsByLevel: <int, int>{},
      tutorialCompleted: false,
    );
  }

  final int highestUnlockedLevel;
  final Map<int, int> bestStarsByLevel;
  final bool tutorialCompleted;

  int starsForLevel(int level) => bestStarsByLevel[level] ?? 0;

  bool isLevelUnlocked(int level) => level <= highestUnlockedLevel;

  int get totalStars => bestStarsByLevel.values.fold<int>(
        0,
        (sum, stars) => sum + stars,
      );

  int get completedLevelCount =>
      bestStarsByLevel.values.where((stars) => stars > 0).length;

  int starsInRange(int startLevel, int endLevel) {
    return bestStarsByLevel.entries.fold<int>(
      0,
      (sum, entry) {
        if (entry.key < startLevel || entry.key > endLevel) {
          return sum;
        }
        return sum + entry.value;
      },
    );
  }

  int completedInRange(int startLevel, int endLevel) {
    return bestStarsByLevel.entries.where((entry) {
      return entry.key >= startLevel &&
          entry.key <= endLevel &&
          entry.value > 0;
    }).length;
  }

  PlayerProgress copyWith({
    int? highestUnlockedLevel,
    Map<int, int>? bestStarsByLevel,
    bool? tutorialCompleted,
  }) {
    return PlayerProgress(
      highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
      bestStarsByLevel: bestStarsByLevel ?? this.bestStarsByLevel,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    );
  }
}

abstract interface class ProgressRepository {
  Future<PlayerProgress> load();

  Future<PlayerProgress> completeLevel({
    required int level,
    required int stars,
  });

  Future<PlayerProgress> markTutorialCompleted();

  Future<PlayerProgress> reset();
}

class PreferencesProgressRepository implements ProgressRepository {
  PreferencesProgressRepository(this._preferences);

  static const _highestUnlockedLevelKey = 'highest_unlocked_level';
  static const _bestStarsByLevelKey = 'best_stars_by_level';
  static const _tutorialCompletedKey = 'tutorial_completed';

  final SharedPreferences _preferences;

  @override
  Future<PlayerProgress> load() async {
    final highestUnlockedLevel =
        _preferences.getInt(_highestUnlockedLevelKey) ?? 1;
    final tutorialCompleted =
        _preferences.getBool(_tutorialCompletedKey) ?? false;
    final starsJson = _preferences.getString(_bestStarsByLevelKey);
    final bestStarsByLevel = <int, int>{};

    if (starsJson != null && starsJson.isNotEmpty) {
      final decoded = jsonDecode(starsJson) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final level = int.tryParse(entry.key);
        final stars = entry.value;
        if (level != null && stars is int) {
          bestStarsByLevel[level] = stars;
        }
      }
    }

    return PlayerProgress(
      highestUnlockedLevel:
          highestUnlockedLevel.clamp(1, maxImplementedLevel).toInt(),
      bestStarsByLevel: Map.unmodifiable(bestStarsByLevel),
      tutorialCompleted: tutorialCompleted,
    );
  }

  @override
  Future<PlayerProgress> completeLevel({
    required int level,
    required int stars,
  }) async {
    final progress = await load();
    final nextStarsByLevel = Map<int, int>.of(progress.bestStarsByLevel);
    final currentBest = nextStarsByLevel[level] ?? 0;
    if (stars > currentBest) {
      nextStarsByLevel[level] = stars.clamp(1, 3).toInt();
    }

    final nextProgress = progress.copyWith(
      highestUnlockedLevel: level < maxImplementedLevel
          ? progress.highestUnlockedLevel
              .clamp(level + 1, maxImplementedLevel)
              .toInt()
          : progress.highestUnlockedLevel,
      bestStarsByLevel: Map.unmodifiable(nextStarsByLevel),
    );
    await _save(nextProgress);
    return nextProgress;
  }

  @override
  Future<PlayerProgress> markTutorialCompleted() async {
    final progress = (await load()).copyWith(tutorialCompleted: true);
    await _save(progress);
    return progress;
  }

  @override
  Future<PlayerProgress> reset() async {
    final progress = PlayerProgress.initial();
    await _save(progress);
    return progress;
  }

  Future<void> _save(PlayerProgress progress) async {
    await _preferences.setInt(
      _highestUnlockedLevelKey,
      progress.highestUnlockedLevel,
    );
    await _preferences.setBool(
      _tutorialCompletedKey,
      progress.tutorialCompleted,
    );
    await _preferences.setString(
      _bestStarsByLevelKey,
      jsonEncode(
        progress.bestStarsByLevel.map(
          (level, stars) => MapEntry('$level', stars),
        ),
      ),
    );
  }
}

class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([PlayerProgress? initialProgress])
      : _progress = initialProgress ?? PlayerProgress.initial();

  PlayerProgress _progress;

  @override
  Future<PlayerProgress> load() async => _progress;

  @override
  Future<PlayerProgress> completeLevel({
    required int level,
    required int stars,
  }) async {
    final nextStarsByLevel = Map<int, int>.of(_progress.bestStarsByLevel);
    final currentBest = nextStarsByLevel[level] ?? 0;
    if (stars > currentBest) {
      nextStarsByLevel[level] = stars.clamp(1, 3).toInt();
    }

    _progress = _progress.copyWith(
      highestUnlockedLevel: level < maxImplementedLevel
          ? _progress.highestUnlockedLevel
              .clamp(level + 1, maxImplementedLevel)
              .toInt()
          : _progress.highestUnlockedLevel,
      bestStarsByLevel: Map.unmodifiable(nextStarsByLevel),
    );
    return _progress;
  }

  @override
  Future<PlayerProgress> markTutorialCompleted() async {
    _progress = _progress.copyWith(tutorialCompleted: true);
    return _progress;
  }

  @override
  Future<PlayerProgress> reset() async {
    _progress = PlayerProgress.initial();
    return _progress;
  }
}
