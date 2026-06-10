import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/game/game_rules.dart';
import 'package:memory_board/src/game/level_config.dart';

void main() {
  test('level table contains 60 levels with expected difficulty anchors', () {
    final levels = buildLevelConfigs();

    expect(levels, hasLength(60));
    expect(levels.first.level, 1);
    expect(levels.first.roomId, 1);
    expect(levels.first.mode, LevelMode.hiddenSet);
    expect(levels.first.gridSize, 3);
    expect(levels.first.objectCount, 3);
    expect(levels[8].level, 9);
    expect(levels[8].gridSize, 4);
    expect(levels[8].objectCount, 6);
    expect(levels[9].level, 10);
    expect(levels[9].gridSize, 4);
    expect(levels[9].objectCount, 6);
    expect(levels[22].level, 23);
    expect(levels[22].gridSize, 6);
    expect(levels[22].objectCount, 8);
    expect(levels[29].level, 30);
    expect(levels[29].gridSize, 6);
    expect(levels[29].objectCount, 10);
    expect(levels[30].level, 31);
    expect(levels[30].roomId, 2);
    expect(levels[30].mode, LevelMode.sequenceTrail);
    expect(levels[30].gridSize, 3);
    expect(levels[30].objectCount, 3);
    expect(levels.last.level, 60);
    expect(levels.last.gridSize, 5);
    expect(levels.last.objectCount, 8);
    expect(levels.every((level) => level.showTime.inSeconds == 4), isTrue);
  });

  test('room table reserves future gameplay modes', () {
    final rooms = buildRoomConfigs();

    expect(rooms, hasLength(3));
    expect(rooms.first.name, 'Magic Glade');
    expect(rooms.first.available, isTrue);
    expect(rooms.first.mode, LevelMode.hiddenSet);
    expect(rooms.first.maxStars, 90);
    expect(rooms[1].name, 'Spark Trail');
    expect(rooms[1].available, isTrue);
    expect(rooms[1].unlockStars, 80);
    expect(rooms[1].mode, LevelMode.sequenceTrail);
    expect(rooms[2].mode, LevelMode.objectFilter);
  });

  test('star calculation follows MVP rules', () {
    expect(starsForMistakes(0), 3);
    expect(starsForMistakes(1), 2);
    expect(starsForMistakes(2), 1);
    expect(starsForMistakes(3), 1);
  });

  test('target generation returns unique cells inside board', () {
    final targets = generateTargets(level: 1, gridSize: 3, objectCount: 3);

    expect(targets, hasLength(3));
    expect(targets.every((cell) => cell >= 0 && cell < 9), isTrue);
  });

  test('target sequence preserves deterministic order', () {
    final sequence = generateTargetSequence(
      level: 31,
      gridSize: 3,
      objectCount: 3,
    );

    expect(sequence, hasLength(3));
    expect(sequence.toSet(), hasLength(3));
    expect(
      sequence,
      generateTargetSequence(level: 31, gridSize: 3, objectCount: 3),
    );
  });

  test('target generation rejects impossible object counts', () {
    expect(
      () => generateTargets(level: 1, gridSize: 3, objectCount: 10),
      throwsArgumentError,
    );
  });
}
