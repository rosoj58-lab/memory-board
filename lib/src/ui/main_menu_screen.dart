import 'package:flutter/material.dart';

import '../app/route_observer.dart';
import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import 'app_chrome.dart';
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
    setState(() {
      _progressFuture = widget.progressRepository.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppBackground(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  key: const ValueKey('menu-settings-button'),
                  onPressed: () {
                    showSettingsDialog(
                      context: context,
                      settingsRepository: widget.settingsRepository,
                    );
                  },
                  child: const Text('Settings'),
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
                          child: SparkMark(size: 92, glowing: true),
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
                            return _MenuProgressSummary(
                              progress: snapshot.data,
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        FilledButton.icon(
                          key: const ValueKey('menu-play-button'),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => LevelSelectionScreen(
                                  progressRepository: widget.progressRepository,
                                  settingsRepository: widget.settingsRepository,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
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
  const _MenuProgressSummary({required this.progress});

  static const int maxLevels = 30;
  static const int maxStars = maxLevels * 3;

  final PlayerProgress? progress;

  @override
  Widget build(BuildContext context) {
    final loadedProgress = progress;
    final totalStars = loadedProgress == null
        ? 0
        : loadedProgress.bestStarsByLevel.values.fold<int>(
            0,
            (sum, stars) => sum + stars,
          );
    final completedLevels = loadedProgress == null
        ? 0
        : loadedProgress.bestStarsByLevel.values
            .where((stars) => stars > 0)
            .length;
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
              value: totalStars / maxStars,
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
                    label: 'Stars', value: '$totalStars/$maxStars'),
                _MenuProgressMetric(
                  label: 'Unlocked',
                  value: '$unlocked/$maxLevels',
                ),
                _MenuProgressMetric(
                  label: 'Completed',
                  value: '$completedLevels/$maxLevels',
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
