import 'package:flutter/material.dart';

import '../app/route_observer.dart';
import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import '../game/level_config.dart';
import 'app_chrome.dart';
import 'gameplay_screen.dart';
import 'level_selection_screen.dart';
import 'settings_dialog.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    required this.progressRepository,
    required this.settingsRepository,
    super.key,
  });

  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> with RouteAware {
  late Future<PlayerProgress> _progressFuture;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    _progressFuture = widget.progressRepository.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) {
        memoryBoardRouteObserver.unsubscribe(this);
      }
      _route = route;
      memoryBoardRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    memoryBoardRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadProgress();
  }

  void _reloadProgress() {
    setState(() {
      _progressFuture = widget.progressRepository.load();
    });
  }

  Future<void> _openSettings() async {
    final reset = await showSettingsDialog(
      context: context,
      settingsRepository: widget.settingsRepository,
      progressRepository: widget.progressRepository,
    );
    if (reset && mounted) {
      _reloadProgress();
    }
  }

  void _openLevels() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelSelectionScreen(
          progressRepository: widget.progressRepository,
          settingsRepository: widget.settingsRepository,
        ),
      ),
    );
  }

  void _startCurrentLevel(PlayerProgress progress) {
    final levels = buildLevelConfigs();
    final levelIndex = (progress.highestUnlockedLevel - 1).clamp(
      0,
      levels.length - 1,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameplayScreen(
          config: levels[levelIndex],
          progressRepository: widget.progressRepository,
          settingsRepository: widget.settingsRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                right: 12,
                child: IconButton.filledTonal(
                  key: const ValueKey('menu-settings-button'),
                  tooltip: 'Settings',
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_rounded),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: AmbientSparkMark(size: 92),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Memory Board',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Train visual memory one board at a time.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSoft,
                                  ),
                        ),
                        const SizedBox(height: 22),
                        FutureBuilder<PlayerProgress>(
                          future: _progressFuture,
                          builder: (context, snapshot) {
                            final progress = snapshot.data;
                            final hasStarted = progress != null &&
                                (progress.tutorialCompleted ||
                                    progress.bestStarsByLevel.isNotEmpty ||
                                    progress.highestUnlockedLevel > 1);
                            return _MenuProgressSummary(
                              progress: progress,
                              hasStarted: hasStarted,
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        FutureBuilder<PlayerProgress>(
                          future: _progressFuture,
                          builder: (context, snapshot) {
                            final progress = snapshot.data;
                            final hasStarted = progress != null &&
                                (progress.tutorialCompleted ||
                                    progress.bestStarsByLevel.isNotEmpty ||
                                    progress.highestUnlockedLevel > 1);
                            return FilledButton.icon(
                              key: const ValueKey('menu-start-button'),
                              onPressed: progress == null
                                  ? null
                                  : () => _startCurrentLevel(progress),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                hasStarted
                                    ? 'Continue Level ${progress.highestUnlockedLevel}'
                                    : 'Start Level 1',
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: const ValueKey('menu-levels-button'),
                          onPressed: _openLevels,
                          icon: const Icon(Icons.grid_view_rounded),
                          label: const Text('Levels'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuProgressSummary extends StatelessWidget {
  const _MenuProgressSummary({
    required this.progress,
    required this.hasStarted,
  });

  final PlayerProgress? progress;
  final bool hasStarted;

  @override
  Widget build(BuildContext context) {
    final loadedProgress = progress;
    final totalStars = loadedProgress?.totalStars ?? 0;
    final completedLevels =
        loadedProgress == null ? 0 : loadedProgress.completedLevelCount;
    final unlocked = loadedProgress?.highestUnlockedLevel ?? 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(210),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x333DEFD6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: totalStars / maxImplementedStars,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: Colors.white12,
              color: AppColors.gold,
            ),
            const SizedBox(height: 10),
            Wrap(
              key: const ValueKey('menu-progress-summary'),
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                _MenuProgressMetric(
                  label: hasStarted ? 'Stars' : 'Goal',
                  value: '$totalStars/$maxImplementedStars',
                ),
                _MenuProgressMetric(
                  label: 'Unlocked',
                  value: '$unlocked/$maxImplementedLevel',
                ),
                _MenuProgressMetric(
                  label: 'Completed',
                  value: '$completedLevels/$maxImplementedLevel',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuProgressMetric extends StatelessWidget {
  const _MenuProgressMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
