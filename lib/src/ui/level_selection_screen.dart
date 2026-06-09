import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../game/level_config.dart';
import 'app_chrome.dart';
import 'gameplay_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({
    required this.progressRepository,
    super.key,
  });

  final ProgressRepository progressRepository;

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
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: AppBackground(
          child: FutureBuilder<PlayerProgress>(
            future: _progressFuture,
            builder: (context, snapshot) {
              final progress = snapshot.data;
              if (progress == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: levels.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        ? () async {
                            final previousHighest =
                                progress.highestUnlockedLevel;
                            setState(() => _highlightedLevel = null);
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GameplayScreen(
                                  config: config,
                                  progressRepository: widget.progressRepository,
                                ),
                              ),
                            );
                            if (!mounted) {
                              return;
                            }
                            final nextProgress =
                                await widget.progressRepository.load();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _highlightedLevel =
                                  nextProgress.highestUnlockedLevel >
                                          previousHighest
                                      ? nextProgress.highestUnlockedLevel
                                      : null;
                              _progressFuture = Future.value(nextProgress);
                            });
                          }
                        : null,
                  );
                },
              );
            },
          ),
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
