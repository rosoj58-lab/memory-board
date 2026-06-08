import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../game/level_config.dart';
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
                  stars: stars,
                  onPressed: unlocked
                      ? () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => GameplayScreen(
                                config: config,
                                progressRepository: widget.progressRepository,
                              ),
                            ),
                          );
                          if (mounted) {
                            setState(() {
                              _progressFuture =
                                  widget.progressRepository.load();
                            });
                          }
                        }
                      : null,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.onPressed,
  });

  final int level;
  final bool unlocked;
  final int stars;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.all(6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    color: const Color(0xFFFFD166),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

