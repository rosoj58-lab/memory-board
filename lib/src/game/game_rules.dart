import 'dart:math';

Set<int> generateTargets({
  required int level,
  required int gridSize,
  required int objectCount,
}) {
  return generateTargetSequence(
    level: level,
    gridSize: gridSize,
    objectCount: objectCount,
  ).toSet();
}

List<int> generateTargetSequence({
  required int level,
  required int gridSize,
  required int objectCount,
}) {
  final cellCount = gridSize * gridSize;
  if (objectCount > cellCount) {
    throw ArgumentError.value(
      objectCount,
      'objectCount',
      'Cannot exceed available board cells.',
    );
  }

  final random = Random(level);
  final shuffled = List<int>.generate(cellCount, (index) => index)
    ..shuffle(random);
  return shuffled.take(objectCount).toList(growable: false);
}

int starsForMistakes(int mistakes) {
  if (mistakes <= 0) {
    return 3;
  }
  if (mistakes == 1) {
    return 2;
  }
  return 1;
}
