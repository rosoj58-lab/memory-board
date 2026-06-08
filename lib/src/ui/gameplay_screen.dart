import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_repository.dart';
import '../game/game_rules.dart';
import '../game/level_config.dart';

enum GamePhase { memorize, recall, won, lost }

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    required this.config,
    required this.progressRepository,
    super.key,
  });

  final LevelConfig config;
  final ProgressRepository progressRepository;

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  static const int maxHearts = 3;

  late Set<int> _targets;
  final Set<int> _correct = <int>{};
  final Set<int> _wrong = <int>{};
  GamePhase _phase = GamePhase.memorize;
  Timer? _timer;
  DateTime? _memorizeStartedAt;
  Duration _remainingMemorizeTime = Duration.zero;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLevel() {
    setState(() {
      _targets = generateTargets(
        level: widget.config.level,
        gridSize: widget.config.gridSize,
        objectCount: widget.config.objectCount,
      );
      _correct.clear();
      _wrong.clear();
      _phase = GamePhase.memorize;
      _mistakes = 0;
      _remainingMemorizeTime = widget.config.showTime;
    });

    _scheduleMemorizeTimer(_remainingMemorizeTime);
  }

  void _scheduleMemorizeTimer(Duration duration) {
    _timer?.cancel();
    _memorizeStartedAt = DateTime.now();
    _timer = Timer(duration, () {
      if (mounted) {
        setState(() => _phase = GamePhase.recall);
      }
    });
  }

  void _pauseMemorizeTimer() {
    if (_phase != GamePhase.memorize || _memorizeStartedAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(_memorizeStartedAt!);
    _remainingMemorizeTime = widget.config.showTime - elapsed;
    if (_remainingMemorizeTime.isNegative) {
      _remainingMemorizeTime = Duration.zero;
    }
    _timer?.cancel();
  }

  void _resumeMemorizeTimer() {
    if (_phase == GamePhase.memorize) {
      _scheduleMemorizeTimer(_remainingMemorizeTime);
    }
  }

  Future<void> _showPauseDialog() async {
    _pauseMemorizeTimer();
    final action = await showDialog<_PauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Paused'),
          actions: [
            TextButton(
              key: const ValueKey('pause-levels-button'),
              onPressed: () => Navigator.of(context).pop(_PauseAction.levels),
              child: const Text('Levels'),
            ),
            TextButton(
              key: const ValueKey('pause-replay-button'),
              onPressed: () => Navigator.of(context).pop(_PauseAction.replay),
              child: const Text('Replay'),
            ),
            FilledButton(
              key: const ValueKey('pause-resume-button'),
              onPressed: () => Navigator.of(context).pop(_PauseAction.resume),
              child: const Text('Resume'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == _PauseAction.levels) {
      Navigator.of(context).pop();
      return;
    }
    if (action == _PauseAction.replay) {
      _startLevel();
      return;
    }
    _resumeMemorizeTimer();
  }

  Future<void> _handleCellTap(int index) async {
    if (_phase != GamePhase.recall ||
        _correct.contains(index) ||
        _wrong.contains(index)) {
      return;
    }

    if (_targets.contains(index)) {
      HapticFeedback.selectionClick();
      setState(() {
        _correct.add(index);
        if (_correct.length == _targets.length) {
          _phase = GamePhase.won;
        }
      });
      if (_phase == GamePhase.won) {
        HapticFeedback.lightImpact();
        await widget.progressRepository.completeLevel(
          level: widget.config.level,
          stars: starsForMistakes(_mistakes),
        );
        await _showWinDialog();
      }
      return;
    }

    HapticFeedback.vibrate();
    setState(() {
      _wrong.add(index);
      _mistakes += 1;
      if (_mistakes >= maxHearts) {
        _phase = GamePhase.lost;
      }
    });

    if (_phase == GamePhase.lost) {
      await _showLoseDialog();
    }
  }

  Future<void> _showWinDialog() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }

    final isFinalLevel = widget.config.level == 30;
    final stars = starsForMistakes(_mistakes);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(isFinalLevel ? 'All levels complete' : 'Level complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFD166),
                    size: 36,
                  );
                }),
              ),
              if (isFinalLevel) ...[
                const SizedBox(height: 16),
                const Text(
                  'Congratulations! You completed all available levels.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              key: const ValueKey('win-levels-button'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Levels'),
            ),
            FilledButton.icon(
              key: const ValueKey('win-replay-button'),
              onPressed: () {
                Navigator.of(context).pop();
                _startLevel();
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay'),
            ),
            if (!isFinalLevel)
              FilledButton.icon(
                key: const ValueKey('win-next-button'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => GameplayScreen(
                        config: buildLevelConfigs()[widget.config.level],
                        progressRepository: widget.progressRepository,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Next'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showLoseDialog() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Try again'),
          content: const Text('All hearts are gone. Replay this board.'),
          actions: [
            TextButton(
              key: const ValueKey('lose-levels-button'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Levels'),
            ),
            FilledButton.icon(
              key: const ValueKey('lose-replay-button'),
              onPressed: () {
                Navigator.of(context).pop();
                _startLevel();
              },
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Replay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final instruction = switch (_phase) {
      GamePhase.memorize => 'Remember the glowing tiles',
      GamePhase.recall => 'Find the hidden spirits',
      GamePhase.won => 'Completed',
      GamePhase.lost => 'Failed',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${config.level}'),
        actions: [
          IconButton(
            key: const ValueKey('pause-button'),
            tooltip: 'Pause',
            onPressed: _showPauseDialog,
            icon: const Icon(Icons.pause_rounded),
          ),
          IconButton(
            key: const ValueKey('replay-button'),
            tooltip: 'Replay',
            onPressed: _startLevel,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_correct.length}/${config.objectCount}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: List.generate(maxHearts, (index) {
                      final active = index < maxHearts - _mistakes;
                      return Icon(
                        active ? Icons.favorite : Icons.heart_broken,
                        color: active ? const Color(0xFFFF6B8A) : Colors.white38,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(instruction, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _Board(
                      gridSize: config.gridSize,
                      targets: _targets,
                      correct: _correct,
                      wrong: _wrong,
                      phase: _phase,
                      onTap: _handleCellTap,
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

class _Board extends StatelessWidget {
  const _Board({
    required this.gridSize,
    required this.targets,
    required this.correct,
    required this.wrong,
    required this.phase,
    required this.onTap,
  });

  final int gridSize;
  final Set<int> targets;
  final Set<int> correct;
  final Set<int> wrong;
  final GamePhase phase;
  final Future<void> Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    final cellCount = gridSize * gridSize;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cellCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final isTarget = targets.contains(index);
        final isCorrect = correct.contains(index);
        final isWrong = wrong.contains(index);
        final isVisible = phase == GamePhase.memorize || isCorrect;

        Color color = const Color(0xFF173A45);
        IconData? icon;
        if (isVisible && isTarget) {
          color = const Color(0xFF1E8F83);
          icon = Icons.auto_awesome;
        }
        if (isCorrect) {
          color = const Color(0xFF2DD4BF);
          icon = Icons.auto_awesome;
        }
        if (isWrong) {
          color = const Color(0xFFC84C5D);
          icon = Icons.close_rounded;
        }

        return InkWell(
          key: ValueKey('board-cell-$index'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => onTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
              boxShadow: isVisible && isTarget
                  ? const [
                      BoxShadow(
                        color: Color(0x773DEFD6),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: icon == null ? 0.85 : 1,
              duration: const Duration(milliseconds: 180),
              child: icon == null
                  ? const SizedBox.shrink()
                  : Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        );
      },
    );
  }
}

enum _PauseAction { resume, replay, levels }
