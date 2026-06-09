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
  return const [
    LevelConfig(
      level: 1,
      gridSize: 3,
      objectCount: 3,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 2,
      gridSize: 3,
      objectCount: 4,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 3,
      gridSize: 4,
      objectCount: 5,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 4,
      gridSize: 4,
      objectCount: 6,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 5,
      gridSize: 4,
      objectCount: 7,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 6,
      gridSize: 5,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 7,
      gridSize: 5,
      objectCount: 8,
      showTime: Duration(milliseconds: 3500),
    ),
    LevelConfig(
      level: 8,
      gridSize: 5,
      objectCount: 9,
      showTime: Duration(milliseconds: 3500),
    ),
    LevelConfig(
      level: 9,
      gridSize: 5,
      objectCount: 9,
      showTime: Duration(seconds: 3),
    ),
    LevelConfig(
      level: 10,
      gridSize: 5,
      objectCount: 10,
      showTime: Duration(seconds: 3),
    ),
    LevelConfig(
      level: 11,
      gridSize: 5,
      objectCount: 10,
      showTime: Duration(milliseconds: 2800),
    ),
    LevelConfig(
      level: 12,
      gridSize: 5,
      objectCount: 11,
      showTime: Duration(milliseconds: 2800),
    ),
    LevelConfig(
      level: 13,
      gridSize: 5,
      objectCount: 11,
      showTime: Duration(milliseconds: 2600),
    ),
    LevelConfig(
      level: 14,
      gridSize: 6,
      objectCount: 12,
      showTime: Duration(seconds: 3),
    ),
    LevelConfig(
      level: 15,
      gridSize: 6,
      objectCount: 12,
      showTime: Duration(milliseconds: 2800),
    ),
    LevelConfig(
      level: 16,
      gridSize: 6,
      objectCount: 13,
      showTime: Duration(milliseconds: 2800),
    ),
    LevelConfig(
      level: 17,
      gridSize: 6,
      objectCount: 13,
      showTime: Duration(milliseconds: 2600),
    ),
    LevelConfig(
      level: 18,
      gridSize: 6,
      objectCount: 14,
      showTime: Duration(milliseconds: 2600),
    ),
    LevelConfig(
      level: 19,
      gridSize: 6,
      objectCount: 14,
      showTime: Duration(milliseconds: 2400),
    ),
    LevelConfig(
      level: 20,
      gridSize: 6,
      objectCount: 15,
      showTime: Duration(milliseconds: 2400),
    ),
    LevelConfig(
      level: 21,
      gridSize: 6,
      objectCount: 15,
      showTime: Duration(milliseconds: 2200),
    ),
    LevelConfig(
      level: 22,
      gridSize: 6,
      objectCount: 16,
      showTime: Duration(milliseconds: 2200),
    ),
    LevelConfig(
      level: 23,
      gridSize: 6,
      objectCount: 16,
      showTime: Duration(seconds: 2),
    ),
    LevelConfig(
      level: 24,
      gridSize: 6,
      objectCount: 17,
      showTime: Duration(milliseconds: 2200),
    ),
    LevelConfig(
      level: 25,
      gridSize: 6,
      objectCount: 17,
      showTime: Duration(seconds: 2),
    ),
    LevelConfig(
      level: 26,
      gridSize: 6,
      objectCount: 18,
      showTime: Duration(milliseconds: 2200),
    ),
    LevelConfig(
      level: 27,
      gridSize: 6,
      objectCount: 18,
      showTime: Duration(seconds: 2),
    ),
    LevelConfig(
      level: 28,
      gridSize: 6,
      objectCount: 19,
      showTime: Duration(milliseconds: 2200),
    ),
    LevelConfig(
      level: 29,
      gridSize: 6,
      objectCount: 19,
      showTime: Duration(seconds: 2),
    ),
    LevelConfig(
      level: 30,
      gridSize: 6,
      objectCount: 20,
      showTime: Duration(seconds: 2),
    ),
  ];
}
