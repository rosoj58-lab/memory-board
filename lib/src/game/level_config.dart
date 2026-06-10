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
const int maxImplementedLevel = 60;
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
      available: true,
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
  return [
    ..._buildRoomLevels(
      roomId: 1,
      startLevel: 1,
      mode: LevelMode.hiddenSet,
      showTime: const Duration(seconds: 4),
      difficulty: _roomOneDifficulty,
    ),
    ..._buildRoomLevels(
      roomId: 2,
      startLevel: 31,
      mode: LevelMode.sequenceTrail,
      showTime: const Duration(seconds: 4),
      difficulty: _roomTwoDifficulty,
    ),
  ];
}

const _roomOneDifficulty = <({int gridSize, int objectCount})>[
  (gridSize: 3, objectCount: 3),
  (gridSize: 3, objectCount: 3),
  (gridSize: 3, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 6),
  (gridSize: 4, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 9),
  (gridSize: 5, objectCount: 9),
  (gridSize: 5, objectCount: 9),
  (gridSize: 5, objectCount: 10),
  (gridSize: 6, objectCount: 8),
  (gridSize: 6, objectCount: 8),
  (gridSize: 6, objectCount: 9),
  (gridSize: 6, objectCount: 9),
  (gridSize: 6, objectCount: 9),
  (gridSize: 6, objectCount: 10),
  (gridSize: 6, objectCount: 10),
  (gridSize: 6, objectCount: 10),
];

const _roomTwoDifficulty = <({int gridSize, int objectCount})>[
  (gridSize: 3, objectCount: 3),
  (gridSize: 3, objectCount: 3),
  (gridSize: 3, objectCount: 3),
  (gridSize: 3, objectCount: 4),
  (gridSize: 3, objectCount: 4),
  (gridSize: 3, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 4),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 5),
  (gridSize: 4, objectCount: 6),
  (gridSize: 4, objectCount: 6),
  (gridSize: 4, objectCount: 6),
  (gridSize: 4, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 6),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 7),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 8),
  (gridSize: 5, objectCount: 8),
];

List<LevelConfig> _buildRoomLevels({
  required int roomId,
  required int startLevel,
  required LevelMode mode,
  required Duration showTime,
  required List<({int gridSize, int objectCount})> difficulty,
}) {
  return [
    for (var index = 0; index < difficulty.length; index += 1)
      LevelConfig(
        level: startLevel + index,
        roomId: roomId,
        mode: mode,
        gridSize: difficulty[index].gridSize,
        objectCount: difficulty[index].objectCount,
        showTime: showTime,
      ),
  ];
}
