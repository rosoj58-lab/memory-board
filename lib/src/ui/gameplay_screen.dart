import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import '../game/game_rules.dart';
import '../game/level_config.dart';
import 'app_chrome.dart';

enum GamePhase { memorize, recall, won, lost }

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({
    required this.config,
    required this.progressRepository,
    required this.settingsRepository,
    super.key,
  });

  final LevelConfig config;
  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;

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
  Timer? _tutorialRecallPromptTimer;
  DateTime? _memorizeStartedAt;
  Duration _remainingMemorizeTime = Duration.zero;
  Duration _activeMemorizeDuration = Duration.zero;
  int _mistakes = 0;
  bool _tutorialEnabled = false;
  bool _tutorialIntroVisible = false;
  bool _tutorialRecallPromptVisible = false;
  bool _hapticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _startLevel();
    _loadTutorialState();
    _loadSettings();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tutorialRecallPromptTimer?.cancel();
    super.dispose();
  }

  void _startLevel() {
    _tutorialRecallPromptTimer?.cancel();
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
      _tutorialRecallPromptVisible = false;
    });

    _scheduleMemorizeTimer(_remainingMemorizeTime);
  }

  Future<void> _loadTutorialState() async {
    if (widget.config.level != 1) {
      return;
    }
    final progress = await widget.progressRepository.load();
    if (!mounted || progress.tutorialCompleted) {
      return;
    }

    _pauseMemorizeTimer();
    setState(() {
      _tutorialEnabled = true;
      _tutorialIntroVisible = true;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.load();
    if (!mounted) {
      return;
    }
    setState(() => _hapticsEnabled = settings.hapticsEnabled);
  }

  void _selectionClick() {
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _lightImpact() {
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _vibrate() {
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.vibrate());
    }
  }

  void _scheduleMemorizeTimer(Duration duration) {
    _timer?.cancel();
    _memorizeStartedAt = DateTime.now();
    _activeMemorizeDuration = duration;
    _timer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _phase = GamePhase.recall;
          _tutorialRecallPromptVisible = false;
        });
        _scheduleTutorialRecallPrompt();
      }
    });
  }

  void _scheduleTutorialRecallPrompt() {
    _tutorialRecallPromptTimer?.cancel();
    if (!_tutorialEnabled || _phase != GamePhase.recall) {
      return;
    }
    _tutorialRecallPromptTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_tutorialEnabled || _phase != GamePhase.recall) {
        return;
      }
      setState(() => _tutorialRecallPromptVisible = true);
    });
  }

  void _hideTutorialRecallPrompt() {
    _tutorialRecallPromptTimer?.cancel();
    if (_tutorialRecallPromptVisible) {
      setState(() => _tutorialRecallPromptVisible = false);
    }
  }

  void _startTutorialMemorizeStep() {
    setState(() => _tutorialIntroVisible = false);
    _resumeMemorizeTimer();
  }

  void _pauseMemorizeTimer() {
    if (_phase != GamePhase.memorize || _memorizeStartedAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(_memorizeStartedAt!);
    _remainingMemorizeTime = _activeMemorizeDuration - elapsed;
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
    _hideTutorialRecallPrompt();
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
    if (_phase == GamePhase.recall) {
      _scheduleTutorialRecallPrompt();
    }
  }

  Future<void> _handleCellTap(int index) async {
    if (_phase != GamePhase.recall ||
        _correct.contains(index) ||
        _wrong.contains(index)) {
      return;
    }

    _hideTutorialRecallPrompt();

    if (_targets.contains(index)) {
      _selectionClick();
      setState(() {
        _correct.add(index);
        if (_correct.length == _targets.length) {
          _phase = GamePhase.won;
        }
      });
      if (_phase == GamePhase.won) {
        _lightImpact();
        if (_tutorialEnabled && widget.config.level == 1) {
          await widget.progressRepository.markTutorialCompleted();
          _tutorialEnabled = false;
        }
        await widget.progressRepository.completeLevel(
          level: widget.config.level,
          stars: starsForMistakes(_mistakes),
        );
        await _showWinDialog();
      } else {
        _scheduleTutorialRecallPrompt();
      }
      return;
    }

    _vibrate();
    setState(() {
      _wrong.add(index);
      _mistakes += 1;
      if (_mistakes >= maxHearts) {
        _phase = GamePhase.lost;
      }
    });

    if (_phase == GamePhase.lost) {
      await _showLoseDialog();
    } else {
      _scheduleTutorialRecallPrompt();
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
      barrierColor: Colors.black.withAlpha(170),
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          content: _WinDialogContent(
            title: isFinalLevel ? 'All levels complete' : 'Level complete',
            stars: stars,
            isFinalLevel: isFinalLevel,
            onMenu: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            onLevels: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            onReplay: () {
              Navigator.of(context).pop();
              _startLevel();
            },
            onNext: isFinalLevel
                ? null
                : () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => GameplayScreen(
                          config: buildLevelConfigs()[widget.config.level],
                          progressRepository: widget.progressRepository,
                          settingsRepository: widget.settingsRepository,
                        ),
                      ),
                    );
                  },
          ),
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
      barrierColor: Colors.black.withAlpha(170),
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          content: _LoseDialogContent(
            onMenu: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            onLevels: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            onReplay: () {
              Navigator.of(context).pop();
              _startLevel();
            },
          ),
        );
      },
    );
  }

  int get _tutorialPointerCell {
    return _targets.firstWhere(
      (target) => !_correct.contains(target),
      orElse: () => _targets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final instruction = switch (_phase) {
      GamePhase.memorize => 'Remember the glowing tiles',
      GamePhase.recall => 'Find the hidden sparks',
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
        child: AppBackground(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_correct.length}/${config.objectCount} found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Row(
                          children: List.generate(maxHearts, (index) {
                            final active = index < maxHearts - _mistakes;
                            return _HeartIndicator(
                              active: active,
                              recentlyLost:
                                  !active && index == maxHearts - _mistakes,
                              index: index,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      instruction,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textSoft,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _LevelInfoStrip(config: config),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _TutorialBoardStack(
                            showPointer: _tutorialRecallPromptVisible,
                            pointerCell: _tutorialPointerCell,
                            gridSize: config.gridSize,
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
                    ),
                  ],
                ),
              ),
              if (_tutorialIntroVisible)
                _TutorialOverlay(
                  title: 'Remember the glowing tiles',
                  body:
                      'Remember where the sparks appear. They will hide soon.',
                  buttonLabel: 'Start',
                  onPressed: _startTutorialMemorizeStep,
                )
              else if (_tutorialRecallPromptVisible)
                const _TutorialPrompt(
                  text: 'Tap the tiles where the sparks were.',
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelInfoStrip extends StatelessWidget {
  const _LevelInfoStrip({required this.config});

  final LevelConfig config;

  @override
  Widget build(BuildContext context) {
    final objectLabel = config.objectCount == 1 ? 'spark' : 'sparks';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xBB102B34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x333DEFD6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Wrap(
          key: const ValueKey('level-info-strip'),
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 6,
          children: [
            _LevelInfoChip(
              icon: Icons.grid_view_rounded,
              label: '${config.gridSize}x${config.gridSize}',
            ),
            _LevelInfoChip(
              icon: Icons.auto_awesome_rounded,
              label: '${config.objectCount} $objectLabel',
            ),
            _LevelInfoChip(
              icon: Icons.timer_rounded,
              label: '${_formatSeconds(config.showTime)} remember',
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelInfoChip extends StatelessWidget {
  const _LevelInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
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

class _HeartIndicator extends StatefulWidget {
  const _HeartIndicator({
    required this.active,
    required this.recentlyLost,
    required this.index,
  });

  final bool active;
  final bool recentlyLost;
  final int index;

  @override
  State<_HeartIndicator> createState() => _HeartIndicatorState();
}

class _HeartIndicatorState extends State<_HeartIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lossController;

  @override
  void initState() {
    super.initState();
    _lossController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    if (widget.recentlyLost) {
      _lossController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _HeartIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.recentlyLost && widget.recentlyLost) {
      _lossController.forward(from: 0);
    }
    if (oldWidget.active != widget.active && widget.active) {
      _lossController.reset();
    }
  }

  @override
  void dispose() {
    _lossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: AnimatedBuilder(
        animation: _lossController,
        builder: (context, child) {
          final value = Curves.easeOut.transform(_lossController.value);
          final shake = widget.recentlyLost
              ? math.sin(value * math.pi * 5) * (1 - value) * 5
              : 0.0;
          final scale =
              widget.recentlyLost ? 1 + math.sin(value * math.pi) * 0.18 : 1.0;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (widget.recentlyLost)
                CustomPaint(
                  size: const Size(34, 34),
                  painter: _HeartLossBurstPainter(value),
                ),
              Transform.translate(
                offset: Offset(shake, 0),
                child: Transform.scale(scale: scale, child: child),
              ),
            ],
          );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            final scale = Tween<double>(begin: 0.72, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: scale, child: child),
            );
          },
          child: Icon(
            widget.active ? Icons.favorite_rounded : Icons.heart_broken_rounded,
            key: ValueKey('heart-${widget.index}-${widget.active}'),
            color: widget.active ? AppColors.danger : const Color(0xFF8FB1B2),
            size: widget.active ? 31 : 30,
            shadows: widget.active
                ? const [
                    Shadow(color: Color(0x55FF6B78), blurRadius: 9),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

class _HeartLossBurstPainter extends CustomPainter {
  const _HeartLossBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }

    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppColors.danger.withAlpha(((1 - progress) * 150).toInt())
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    const rays = 7;
    for (var index = 0; index < rays; index += 1) {
      final angle = -math.pi / 2 + index * (math.pi * 2 / rays);
      final startRadius = 8 + progress * 3;
      final endRadius = 11 + progress * 11;
      final start = center +
          Offset(math.cos(angle) * startRadius, math.sin(angle) * startRadius);
      final end = center +
          Offset(math.cos(angle) * endRadius, math.sin(angle) * endRadius);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeartLossBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _TutorialBoardStack extends StatelessWidget {
  const _TutorialBoardStack({
    required this.showPointer,
    required this.pointerCell,
    required this.gridSize,
    required this.child,
  });

  final bool showPointer;
  final int pointerCell;
  final int gridSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final row = pointerCell ~/ gridSize;
    final column = pointerCell % gridSize;
    final left = (column + 0.5) / gridSize;
    final top = (row + 0.5) / gridSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (showPointer)
              Positioned(
                left: constraints.maxWidth * left - 14,
                top: constraints.maxHeight * top - 14,
                child: const _TutorialHandPointer(),
              ),
          ],
        );
      },
    );
  }
}

class _TutorialHandPointer extends StatefulWidget {
  const _TutorialHandPointer();

  @override
  State<_TutorialHandPointer> createState() => _TutorialHandPointerState();
}

class _TutorialHandPointerState extends State<_TutorialHandPointer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ScaleTransition(
        scale: _scale,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xEE102B34),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x663DEFD6),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.touch_app_rounded,
              key: ValueKey('tutorial-hand-pointer'),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialOverlay extends StatelessWidget {
  const _TutorialOverlay({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xCC06181D)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF102B34),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x663DEFD6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('tutorial-start-button'),
                      onPressed: onPressed,
                      child: Text(buttonLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialPrompt extends StatelessWidget {
  const _TutorialPrompt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xEE102B34),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x663DEFD6)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            text,
            key: const ValueKey('tutorial-recall-prompt'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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
        bool showSpark = false;
        IconData? statusIcon;
        if (isVisible && isTarget) {
          color = AppColors.surfaceAlt;
          showSpark = true;
        }
        if (isCorrect) {
          color = const Color(0xFF127865);
          showSpark = true;
        }
        if (isWrong) {
          color = const Color(0xFF812D3E);
          statusIcon = Icons.close_rounded;
        }

        return _BoardCell(
          index: index,
          color: color,
          glowing: isVisible && isTarget,
          showSpark: showSpark,
          statusIcon: statusIcon,
          isCorrect: isCorrect,
          isWrong: isWrong,
          onTap: () => onTap(index),
        );
      },
    );
  }
}

class _BoardCell extends StatefulWidget {
  const _BoardCell({
    required this.index,
    required this.color,
    required this.glowing,
    required this.showSpark,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
    this.statusIcon,
  });

  final int index;
  final Color color;
  final bool glowing;
  final bool showSpark;
  final bool isCorrect;
  final bool isWrong;
  final IconData? statusIcon;
  final VoidCallback onTap;

  @override
  State<_BoardCell> createState() => _BoardCellState();
}

class _BoardCellState extends State<_BoardCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant _BoardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!oldWidget.isCorrect && widget.isCorrect) ||
        (!oldWidget.isWrong && widget.isWrong)) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _feedbackController,
      builder: (context, child) {
        final value = _feedbackController.value;
        final shake = widget.isWrong ? math.sin(value * math.pi * 6) * 5 : 0.0;
        final bounce =
            widget.isCorrect ? 1 + math.sin(value * math.pi) * 0.08 : 1.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(scale: bounce, child: child),
        );
      },
      child: InkWell(
        key: ValueKey('board-cell-${widget.index}'),
        borderRadius: BorderRadius.circular(8),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.glowing ? AppColors.primary : Colors.white24,
            ),
            boxShadow: widget.glowing
                ? const [
                    BoxShadow(
                      color: Color(0x773DEFD6),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) {
              final eased = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              );
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: eased, child: child),
              );
            },
            child: widget.showSpark
                ? SparkMark(
                    key: const ValueKey('cell-spark'),
                    size: 34,
                    glowing: widget.isCorrect,
                  )
                : widget.statusIcon == null
                    ? const SizedBox.shrink(key: ValueKey('cell-empty'))
                    : Icon(
                        widget.statusIcon,
                        key: const ValueKey('cell-status'),
                        color: Colors.white,
                        size: 30,
                      ),
          ),
        ),
      ),
    );
  }
}

enum _PauseAction { resume, replay, levels }

class _WinDialogContent extends StatefulWidget {
  const _WinDialogContent({
    required this.title,
    required this.stars,
    required this.isFinalLevel,
    required this.onMenu,
    required this.onLevels,
    required this.onReplay,
    required this.onNext,
  });

  final String title;
  final int stars;
  final bool isFinalLevel;
  final VoidCallback onMenu;
  final VoidCallback onLevels;
  final VoidCallback onReplay;
  final VoidCallback? onNext;

  @override
  State<_WinDialogContent> createState() => _WinDialogContentState();
}

class _WinDialogContentState extends State<_WinDialogContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final nextPulseProgress =
            ((_controller.value - 0.66) / 0.34).clamp(0.0, 1.0);
        final nextButtonScale =
            1 + math.sin(nextPulseProgress * math.pi) * 0.045;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              key: const ValueKey('win-stars-row'),
              width: 148,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(148, 64),
                    painter: _WinParticlesPainter(_controller.value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final threshold = 0.18 + index * 0.18;
                      final visible = _controller.value >= threshold;
                      return AnimatedScale(
                        duration: const Duration(milliseconds: 180),
                        scale: visible ? 1 : 0.4,
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: visible ? 1 : 0,
                          child: Icon(
                            index < widget.stars
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.gold,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            if (widget.isFinalLevel) ...[
              const SizedBox(height: 16),
              const Text(
                'Congratulations! You completed all available levels.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 22),
            if (widget.onNext != null) ...[
              Transform.scale(
                scale: nextButtonScale,
                child: _DialogActionButton(
                  key: const ValueKey('win-next-button'),
                  onPressed: widget.onNext!,
                  icon: Icons.arrow_forward_rounded,
                  style: _DialogActionStyle.primary,
                  child: const Text('Next'),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              _DialogActionButton(
                key: const ValueKey('win-levels-button'),
                onPressed: widget.onLevels,
                icon: Icons.grid_view_rounded,
                style: _DialogActionStyle.primary,
                child: const Text('Levels'),
              ),
              const SizedBox(height: 8),
            ],
            _DialogActionButton(
              key: const ValueKey('win-replay-button'),
              onPressed: widget.onReplay,
              icon: Icons.replay_rounded,
              style: _DialogActionStyle.secondary,
              child: const Text('Replay'),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                if (widget.onNext != null)
                  _DialogActionButton(
                    key: const ValueKey('win-levels-button'),
                    onPressed: widget.onLevels,
                    style: _DialogActionStyle.text,
                    child: const Text('Levels'),
                  ),
                _DialogActionButton(
                  key: const ValueKey('win-menu-button'),
                  onPressed: widget.onMenu,
                  style: _DialogActionStyle.text,
                  child: const Text('Menu'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LoseDialogContent extends StatelessWidget {
  const _LoseDialogContent({
    required this.onMenu,
    required this.onLevels,
    required this.onReplay,
  });

  final VoidCallback onMenu;
  final VoidCallback onLevels;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Try again',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        const Text(
          'All hearts are gone. Replay this board.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        _DialogActionButton(
          key: const ValueKey('lose-replay-button'),
          onPressed: onReplay,
          icon: Icons.replay_rounded,
          style: _DialogActionStyle.primary,
          child: const Text('Replay'),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            _DialogActionButton(
              key: const ValueKey('lose-levels-button'),
              onPressed: onLevels,
              style: _DialogActionStyle.text,
              child: const Text('Levels'),
            ),
            _DialogActionButton(
              key: const ValueKey('lose-menu-button'),
              onPressed: onMenu,
              style: _DialogActionStyle.text,
              child: const Text('Menu'),
            ),
          ],
        ),
      ],
    );
  }
}

enum _DialogActionStyle { primary, secondary, text }

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.style = _DialogActionStyle.text,
    super.key,
  });

  static const double width = 184;

  final VoidCallback onPressed;
  final Widget child;
  final IconData? icon;
  final _DialogActionStyle style;

  @override
  Widget build(BuildContext context) {
    final buttonChild = icon == null
        ? child
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              child,
            ],
          );

    return SizedBox(
      width: style == _DialogActionStyle.text ? null : width,
      child: switch (style) {
        _DialogActionStyle.primary => FilledButton(
            onPressed: onPressed,
            child: buttonChild,
          ),
        _DialogActionStyle.secondary => OutlinedButton(
            onPressed: onPressed,
            child: buttonChild,
          ),
        _DialogActionStyle.text => TextButton(
            onPressed: onPressed,
            child: buttonChild,
          ),
      },
    );
  }
}

class _WinParticlesPainter extends CustomPainter {
  const _WinParticlesPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(progress.clamp(0, 1).toDouble());
    final opacity = (1 - progress).clamp(0, 1).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.primary.withAlpha((180 * opacity).toInt());
    const angles = <double>[
      -2.8,
      -2.1,
      -1.35,
      -0.55,
      0.25,
      0.95,
      1.65,
      2.35,
    ];

    for (var i = 0; i < angles.length; i += 1) {
      final distance = 14 + eased * (18 + i % 3 * 5);
      final offset = Offset(
        math.cos(angles[i]) * distance,
        math.sin(angles[i]) * distance,
      );
      canvas.drawCircle(center + offset, 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WinParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
