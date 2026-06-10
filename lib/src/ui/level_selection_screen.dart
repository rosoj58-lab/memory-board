import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import '../game/level_config.dart';
import 'app_chrome.dart';
import 'gameplay_screen.dart';
import 'settings_dialog.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({
    required this.progressRepository,
    required this.settingsRepository,
    super.key,
  });

  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late Future<PlayerProgress> _progressFuture;
  final ScrollController _scrollController = ScrollController();
  int? _highlightedLevel;

  @override
  void initState() {
    super.initState();
    _progressFuture = widget.progressRepository.load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levels = buildLevelConfigs();
    final rooms = buildRoomConfigs();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Levels'),
        actions: [
          IconButton(
            key: const ValueKey('levels-settings-button'),
            tooltip: 'Settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: AppBackground(
          child: FutureBuilder<PlayerProgress>(
            future: _progressFuture,
            builder: (context, snapshot) {
              final progress = snapshot.data;
              if (progress == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final lockedRoom = _lockedPlayableRoom(progress, rooms);

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _RoomOverview(
                      rooms: rooms,
                      progress: progress,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _NextChallengePanel(
                      config: levels[progress.highestUnlockedLevel - 1],
                      onStart: () => _openLevel(
                        config: levels[progress.highestUnlockedLevel - 1],
                        progress: progress,
                      ),
                    ),
                  ),
                  if (lockedRoom != null)
                    SliverToBoxAdapter(
                      child: _StarImprovePanel(
                        room: lockedRoom,
                        missingStars:
                            lockedRoom.unlockStars - progress.totalStars,
                        candidates: _starImproveCandidates(
                          levels: levels,
                          progress: progress,
                        ),
                        onOpenLevel: (config) => _openLevel(
                          config: config,
                          progress: progress,
                        ),
                      ),
                    ),
                  for (final room in rooms)
                    ..._buildRoomLevelSlivers(
                      room: room,
                      levels: levels,
                      progress: progress,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  RoomConfig? _lockedPlayableRoom(
    PlayerProgress progress,
    List<RoomConfig> rooms,
  ) {
    for (final room in rooms) {
      if (room.available &&
          room.unlockStars > 0 &&
          progress.totalStars < room.unlockStars) {
        return room;
      }
    }
    return null;
  }

  List<_StarImproveCandidate> _starImproveCandidates({
    required List<LevelConfig> levels,
    required PlayerProgress progress,
  }) {
    final candidates = <_StarImproveCandidate>[
      for (final config in levels)
        if (progress.isLevelUnlocked(config.level))
          if (progress.starsForLevel(config.level) > 0 &&
              progress.starsForLevel(config.level) < 3)
            _StarImproveCandidate(
              config: config,
              stars: progress.starsForLevel(config.level),
            ),
    ];
    candidates.sort((a, b) {
      final upliftCompare = b.availableStars.compareTo(a.availableStars);
      if (upliftCompare != 0) {
        return upliftCompare;
      }
      return a.config.level.compareTo(b.config.level);
    });
    return candidates.take(4).toList(growable: false);
  }

  List<Widget> _buildRoomLevelSlivers({
    required RoomConfig room,
    required List<LevelConfig> levels,
    required PlayerProgress progress,
  }) {
    final roomLevels = levels.where((level) => room.containsLevel(level.level));
    if (roomLevels.isEmpty) {
      return const <Widget>[];
    }

    final levelList = roomLevels.toList(growable: false);
    final roomUnlocked =
        room.available && progress.totalStars >= room.unlockStars;
    final current = room.containsLevel(progress.highestUnlockedLevel);

    return [
      SliverToBoxAdapter(
        child: _LevelSectionHeader(
          room: room,
          unlocked: roomUnlocked,
          current: current,
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        sliver: SliverGrid.builder(
          itemCount: levelList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final config = levelList[index];
            final unlocked = progress.isLevelUnlocked(config.level);
            final stars = progress.starsForLevel(config.level);
            final currentLevel = unlocked &&
                stars == 0 &&
                config.level == progress.highestUnlockedLevel;
            return _LevelTile(
              level: config.level,
              unlocked: unlocked,
              current: currentLevel,
              highlighted: _highlightedLevel == config.level,
              stars: stars,
              onPressed: unlocked
                  ? () => _openLevel(
                        config: config,
                        progress: progress,
                      )
                  : null,
            );
          },
        ),
      ),
    ];
  }

  Future<void> _openLevel({
    required LevelConfig config,
    required PlayerProgress progress,
  }) async {
    final previousHighest = progress.highestUnlockedLevel;
    setState(() => _highlightedLevel = null);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(
          config: config,
          progressRepository: widget.progressRepository,
          settingsRepository: widget.settingsRepository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final nextProgress = await widget.progressRepository.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedLevel = nextProgress.highestUnlockedLevel > previousHighest
          ? nextProgress.highestUnlockedLevel
          : null;
      _progressFuture = Future.value(nextProgress);
    });
  }

  Future<void> _openSettings() async {
    final reset = await showSettingsDialog(
      context: context,
      settingsRepository: widget.settingsRepository,
      progressRepository: widget.progressRepository,
    );
    if (!reset || !mounted) {
      return;
    }

    final progress = await widget.progressRepository.load();
    setState(() {
      _highlightedLevel = null;
      _progressFuture = Future.value(progress);
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }
}

class _NextChallengePanel extends StatelessWidget {
  const _NextChallengePanel({
    required this.config,
    required this.onStart,
  });

  final LevelConfig config;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final primaryMetric = _primaryChallengeMetric(config);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(210),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x333DEFD6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Next challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('next-challenge-start-button'),
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                key: const ValueKey('next-challenge-info'),
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryMetric(
                    icon: Icons.flag_rounded,
                    label: 'Level',
                    value: '${config.level}',
                  ),
                  _SummaryMetric(
                    icon: Icons.grid_view_rounded,
                    label: 'Board',
                    value: '${config.gridSize}x${config.gridSize}',
                  ),
                  _SummaryMetric(
                    icon: primaryMetric.icon,
                    label: primaryMetric.label,
                    value: primaryMetric.value,
                  ),
                  _SummaryMetric(
                    icon: Icons.timer_rounded,
                    label: config.mode == LevelMode.sequenceTrail
                        ? 'Trail'
                        : 'Remember',
                    value: _formatSeconds(config.showTime),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeMetricData {
  const _ChallengeMetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

_ChallengeMetricData _primaryChallengeMetric(LevelConfig config) {
  switch (config.mode) {
    case LevelMode.sequenceTrail:
      return _ChallengeMetricData(
        icon: Icons.route_rounded,
        label: 'Repeat',
        value: '${config.objectCount}-step trail',
      );
    case LevelMode.objectFilter:
      return const _ChallengeMetricData(
        icon: Icons.filter_alt_rounded,
        label: 'Pick',
        value: 'target objects',
      );
    case LevelMode.hiddenSet:
      final objectLabel = config.objectCount == 1 ? 'spark' : 'sparks';
      return _ChallengeMetricData(
        icon: Icons.auto_awesome_rounded,
        label: 'Find',
        value: '${config.objectCount} $objectLabel',
      );
  }
}

class _LevelSectionHeader extends StatelessWidget {
  const _LevelSectionHeader({
    required this.room,
    required this.unlocked,
    required this.current,
  });

  final RoomConfig room;
  final bool unlocked;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: locked ? Colors.white12 : AppColors.surface.withAlpha(220),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: current ? AppColors.gold : const Color(0x333DEFD6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                _roomIcon(room.mode, locked: locked),
                color: locked ? Colors.white54 : AppColors.gold,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room ${room.id} · ${room.name}',
                  key: ValueKey('level-section-room-${room.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: locked ? Colors.white60 : Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  locked
                      ? 'Unlock at ${room.unlockStars} stars'
                      : '${room.levelStart}-${room.levelEnd} · ${_modeCopy(room.mode)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: locked ? Colors.white54 : AppColors.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _roomIcon(LevelMode mode, {required bool locked}) {
  if (locked) {
    return Icons.lock_rounded;
  }
  switch (mode) {
    case LevelMode.hiddenSet:
      return Icons.grid_view_rounded;
    case LevelMode.sequenceTrail:
      return Icons.route_rounded;
    case LevelMode.objectFilter:
      return Icons.filter_alt_rounded;
  }
}

String _modeCopy(LevelMode mode) {
  switch (mode) {
    case LevelMode.hiddenSet:
      return 'Find hidden sparks';
    case LevelMode.sequenceTrail:
      return 'Repeat the trail in order';
    case LevelMode.objectFilter:
      return 'Pick requested objects';
  }
}

class _StarImproveCandidate {
  const _StarImproveCandidate({
    required this.config,
    required this.stars,
  });

  final LevelConfig config;
  final int stars;

  int get availableStars => 3 - stars;
}

class _StarImprovePanel extends StatelessWidget {
  const _StarImprovePanel({
    required this.room,
    required this.missingStars,
    required this.candidates,
    required this.onOpenLevel,
  });

  final RoomConfig room;
  final int missingStars;
  final List<_StarImproveCandidate> candidates;
  final ValueChanged<LevelConfig> onOpenLevel;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        key: const ValueKey('star-improve-panel'),
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(210),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFD86B)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Improve stars',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '$missingStars stars needed for ${room.name}',
                key: const ValueKey('star-improve-needed'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSoft,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final candidate in candidates)
                    _StarImproveButton(
                      candidate: candidate,
                      onPressed: () => onOpenLevel(candidate.config),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarImproveButton extends StatelessWidget {
  const _StarImproveButton({
    required this.candidate,
    required this.onPressed,
  });

  final _StarImproveCandidate candidate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: ValueKey('star-improve-level-${candidate.config.level}'),
      onPressed: onPressed,
      icon: const Icon(Icons.replay_rounded, size: 18),
      label: Text('Level ${candidate.config.level} ${candidate.stars}/3'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x55FFD86B)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _RoomOverview extends StatelessWidget {
  const _RoomOverview({
    required this.rooms,
    required this.progress,
  });

  final List<RoomConfig> rooms;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        key: const ValueKey('room-overview'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final room = rooms[index];
          final roomStars = progress.starsInRange(
            room.levelStart,
            room.levelEnd,
          );
          final completed = progress.completedInRange(
            room.levelStart,
            room.levelEnd,
          );
          final unlocked =
              room.available && progress.totalStars >= room.unlockStars;
          final current = room.containsLevel(progress.highestUnlockedLevel);
          return _RoomCard(
            room: room,
            stars: roomStars,
            completed: completed,
            unlocked: unlocked,
            current: current,
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.stars,
    required this.completed,
    required this.unlocked,
    required this.current,
  });

  final RoomConfig room;
  final int stars;
  final int completed;
  final bool unlocked;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final locked = !unlocked;
    final progress = (stars / room.maxStars).clamp(0.0, 1.0);
    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: 228),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: current
              ? const Color(0xDD103A42)
              : AppColors.surface.withAlpha(locked ? 150 : 210),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: current ? AppColors.gold : const Color(0x333DEFD6),
            width: current ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_rounded : Icons.auto_awesome_rounded,
                    color: locked ? Colors.white54 : AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Room ${room.id}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: locked ? Colors.white60 : Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (current)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        child: Text(
                          'Now',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: locked ? Colors.white60 : Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                room.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: locked ? Colors.white54 : AppColors.textSoft,
                    ),
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white12,
                color: locked ? Colors.white38 : AppColors.gold,
              ),
              const SizedBox(height: 7),
              Text(
                locked
                    ? 'Unlock at ${room.unlockStars} stars'
                    : '$completed/${room.levelCount} levels | $stars/${room.maxStars} stars',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: locked ? Colors.white54 : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatSeconds(Duration duration) {
  final milliseconds = duration.inMilliseconds;
  if (milliseconds % Duration.millisecondsPerSecond == 0) {
    return '${duration.inSeconds}s';
  }
  final seconds = milliseconds / Duration.millisecondsPerSecond;
  return '${seconds.toStringAsFixed(1)}s';
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSoft, size: 16),
            const SizedBox(width: 6),
            Text(
              '$label $value',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.current,
    required this.highlighted,
    required this.stars,
    required this.onPressed,
  });

  final int level;
  final bool unlocked;
  final bool current;
  final bool highlighted;
  final int stars;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('level-tile-pulse-$level-$highlighted'),
      tween: Tween<double>(begin: 0, end: highlighted || current ? 1 : 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final pulse =
            (highlighted || current) ? math.sin(value * math.pi) : 0.0;
        return Transform.scale(
          scale: 1 + pulse * 0.06,
          child: child,
        );
      },
      child: DecoratedBox(
        key: highlighted ? ValueKey('level-unlocked-pulse-$level') : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: highlighted || current
              ? const [
                  BoxShadow(
                    color: Color(0x55FFD166),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: FilledButton.tonal(
          key: ValueKey('level-tile-$level'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: highlighted
                ? AppColors.primaryStrong
                : current
                    ? const Color(0xFF15535B)
                    : unlocked
                        ? AppColors.surfaceAlt
                        : AppColors.surface.withAlpha(150),
            foregroundColor: unlocked ? Colors.white : Colors.white54,
            padding: const EdgeInsets.all(6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: highlighted || current
                  ? const BorderSide(color: AppColors.gold, width: 1.5)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (current)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Next',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.background,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                )
              else
                Icon(
                  unlocked ? Icons.grid_view_rounded : Icons.lock_rounded,
                  size: 18,
                ),
              const SizedBox(height: 3),
              Text('$level'),
              if (unlocked && stars > 0)
                FittedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return Icon(
                        index < stars ? Icons.star : Icons.star_border,
                        size: 12,
                        color: AppColors.gold,
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
