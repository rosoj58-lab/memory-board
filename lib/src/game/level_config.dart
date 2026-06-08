class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.gridSize,
    required this.objectCount,
    required this.showTime,
  });

  final int level;
  final int gridSize;
  final int objectCount;
  final Duration showTime;
}

List<LevelConfig> buildLevelConfigs() {
  return List.generate(30, (index) {
    final level = index + 1;
    if (level <= 3) {
      return LevelConfig(
        level: level,
        gridSize: 3,
        objectCount: 3,
        showTime: const Duration(seconds: 4),
      );
    }
    if (level <= 8) {
      return LevelConfig(
        level: level,
        gridSize: 3,
        objectCount: 4,
        showTime: Duration(milliseconds: level <= 5 ? 4000 : 3500),
      );
    }
    if (level <= 13) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 4,
        showTime: const Duration(milliseconds: 3500),
      );
    }
    if (level <= 18) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 5,
        showTime: const Duration(seconds: 3),
      );
    }
    if (level <= 22) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 6,
        showTime: const Duration(milliseconds: 2800),
      );
    }
    if (level <= 26) {
      return LevelConfig(
        level: level,
        gridSize: 5,
        objectCount: 6,
        showTime: const Duration(seconds: 3),
      );
    }
    if (level <= 28) {
      return LevelConfig(
        level: level,
        gridSize: 5,
        objectCount: 7,
        showTime: const Duration(milliseconds: 2700),
      );
    }
    return LevelConfig(
      level: level,
      gridSize: 5,
      objectCount: 8,
      showTime: const Duration(milliseconds: 2500),
    );
  });
}

