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
  int? _highlightedLevel;

  @override
  void initState() {
    super.initState();
    _progressFuture = widget.progressRepository.load();
  }

  @override
  Widget build(BuildContext context) {
    final levels = buildLevelConfigs();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Levels'),
        actions: [
          IconButton(
            key: const ValueKey('reset-progress-button'),
            tooltip: 'Reset progress',
            onPressed: _showResetProgressDialog,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            key: const ValueKey('levels-settings-button'),
            tooltip: 'Settings',
            onPressed: () {
              showSettingsDialog(
                context: context,
                settingsRepository: widget.settingsRepository,
              );
            },
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

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProgressSummary(progress: progress),
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid.builder(
                      itemCount: levels.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final config = levels[index];
                        final unlocked = progress.isLevelUnlocked(config.level);
                        final stars = progress.starsForLevel(config.level);
                        return _LevelTile(
                          level: config.level,
                          unlocked: unlocked,
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
                ],
              );
            },
          ),
        ),
      ),
    );
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

  Future<void> _showResetProgressDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset progress?'),
          content:
              const Text('Levels, stars, and tutorial progress will reset.'),
          actions: [
            TextButton(
              key: const ValueKey('reset-cancel-button'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('reset-confirm-button'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final progress = await widget.progressRepository.reset();
    if (!mounted) {
      return;
    }
    setState(() {
      _highlightedLevel = null;
      _progressFuture = Future.value(progress);
    });
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
    final objectLabel = config.objectCount == 1 ? 'spirit' : 'spirits';
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
                    icon: Icons.auto_awesome_rounded,
                    label: 'Find',
                    value: '${config.objectCount} $objectLabel',
                  ),
                  _SummaryMetric(
                    icon: Icons.timer_rounded,
                    label: 'Watch',
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

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.progress});

  static const int maxLevels = 30;
  static const int maxStars = maxLevels * 3;

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final totalStars = progress.bestStarsByLevel.values.fold<int>(
      0,
      (sum, stars) => sum + stars,
    );
    final completedLevels =
        progress.bestStarsByLevel.values.where((stars) => stars > 0).length;
    final starProgress = totalStars / maxStars;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withAlpha(210),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Journey progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: starProgress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(999),
                backgroundColor: Colors.white12,
                color: AppColors.gold,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SummaryMetric(
                    icon: Icons.lock_open_rounded,
                    label: 'Unlocked',
                    value: '${progress.highestUnlockedLevel}/$maxLevels',
                  ),
                  _SummaryMetric(
                    icon: Icons.star_rounded,
                    label: 'Stars',
                    value: '$totalStars/$maxStars',
                  ),
                  _SummaryMetric(
                    icon: Icons.flag_rounded,
                    label: 'Completed',
                    value: '$completedLevels/$maxLevels',
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
    required this.highlighted,
    required this.stars,
    required this.onPressed,
  });

  final int level;
  final bool unlocked;
  final bool highlighted;
  final int stars;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('level-tile-pulse-$level-$highlighted'),
      tween: Tween<double>(begin: 0, end: highlighted ? 1 : 0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final pulse = highlighted ? math.sin(value * math.pi) : 0.0;
        return Transform.scale(
          scale: 1 + pulse * 0.06,
          child: child,
        );
      },
      child: DecoratedBox(
        key: highlighted ? ValueKey('level-unlocked-pulse-$level') : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: highlighted
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
                : unlocked
                    ? AppColors.surfaceAlt
                    : AppColors.surface.withAlpha(150),
            foregroundColor: unlocked ? Colors.white : Colors.white54,
            padding: const EdgeInsets.all(6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: highlighted
                  ? const BorderSide(color: AppColors.gold, width: 1.5)
                  : BorderSide.none,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
