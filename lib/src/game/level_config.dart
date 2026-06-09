enum LevelMode {
  hiddenSet,
  sequenceTrail,
  objectFilter,
}

class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.roomId,
    required this.mode,
    required this.gridSize,
    required this.objectCount,
    required this.showTime,
  });

  final int level;
  final int roomId;
  final LevelMode mode;
  final int gridSize;
  final int objectCount;
  final Duration showTime;
}

class RoomConfig {
  const RoomConfig({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.levelStart,
    required this.levelEnd,
    required this.unlockStars,
    required this.mode,
    required this.available,
  });

  final int id;
  final String name;
  final String subtitle;
  final int levelStart;
  final int levelEnd;
  final int unlockStars;
  final LevelMode mode;
  final bool available;

  int get levelCount => levelEnd - levelStart + 1;

  int get maxStars => levelCount * 3;

  bool containsLevel(int level) => level >= levelStart && level <= levelEnd;
}

const int roomLevelCount = 30;
const int maxImplementedLevel = 30;
const int maxImplementedStars = maxImplementedLevel * 3;

List<RoomConfig> buildRoomConfigs() {
  return const [
    RoomConfig(
      id: 1,
      name: 'Magic Glade',
      subtitle: 'Find every hidden spark',
      levelStart: 1,
      levelEnd: 30,
      unlockStars: 0,
      mode: LevelMode.hiddenSet,
      available: true,
    ),
    RoomConfig(
      id: 2,
      name: 'Spark Trail',
      subtitle: 'Repeat the glowing path in order',
      levelStart: 31,
      levelEnd: 60,
      unlockStars: 80,
      mode: LevelMode.sequenceTrail,
      available: false,
    ),
    RoomConfig(
      id: 3,
      name: 'Moon Garden',
      subtitle: 'Pick only the requested magic objects',
      levelStart: 61,
      levelEnd: 90,
      unlockStars: 170,
      mode: LevelMode.objectFilter,
      available: false,
    ),
  ];
}

List<LevelConfig> buildLevelConfigs() {
  return const [
    LevelConfig(
      level: 1,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 3,
      objectCount: 3,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 2,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 3,
      objectCount: 3,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 3,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 3,
      objectCount: 4,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 4,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 4,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 5,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 4,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 6,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 5,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 7,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 5,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 8,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 5,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 9,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 6,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 10,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 4,
      objectCount: 6,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 11,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 6,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 12,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 6,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 13,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 7,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 14,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 7,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 15,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 7,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 16,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 17,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 18,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 19,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 20,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 21,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 22,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 5,
      objectCount: 10,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 23,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 24,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 8,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 25,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 26,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 27,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 9,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 28,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 10,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 29,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 10,
      showTime: Duration(seconds: 4),
    ),
    LevelConfig(
      level: 30,
      roomId: 1,
      mode: LevelMode.hiddenSet,
      gridSize: 6,
      objectCount: 10,
      showTime: Duration(seconds: 4),
    ),
  ];
}
