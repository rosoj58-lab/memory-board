import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MemoryBoardApp());
}

class MemoryBoardApp extends StatelessWidget {
  const MemoryBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF42D6C5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}

class LevelConfig {
  const LevelConfig({
    required this.level,
    required this.gridSize,
    required this.objectCount,
    required this.showTime,
  });

  final int level;
  final int gridSize;
  final int objectCount;
  final Duration showTime;
}

List<LevelConfig> buildLevels() {
  return List.generate(30, (index) {
    final level = index + 1;
    if (level <= 3) {
      return LevelConfig(
        level: level,
        gridSize: 3,
        objectCount: 3,
        showTime: const Duration(seconds: 4),
      );
    }
    if (level <= 8) {
      return LevelConfig(
        level: level,
        gridSize: 3,
        objectCount: 4,
        showTime: Duration(milliseconds: level <= 5 ? 4000 : 3500),
      );
    }
    if (level <= 13) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 4,
        showTime: const Duration(milliseconds: 3500),
      );
    }
    if (level <= 18) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 5,
        showTime: const Duration(seconds: 3),
      );
    }
    if (level <= 22) {
      return LevelConfig(
        level: level,
        gridSize: 4,
        objectCount: 6,
        showTime: const Duration(milliseconds: 2800),
      );
    }
    if (level <= 26) {
      return LevelConfig(
        level: level,
        gridSize: 5,
        objectCount: 6,
        showTime: const Duration(seconds: 3),
      );
    }
    if (level <= 28) {
      return LevelConfig(
        level: level,
        gridSize: 5,
        objectCount: 7,
        showTime: const Duration(milliseconds: 2700),
      );
    }
    return LevelConfig(
      level: level,
      gridSize: 5,
      objectCount: 8,
      showTime: const Duration(milliseconds: 2500),
    );
  });
}

enum GamePhase { memorize, recall, won, lost }

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.auto_awesome, size: 72, color: Color(0xFF7EF7DF)),
              const SizedBox(height: 24),
              Text(
                'Memory Board',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Train visual memory one board at a time.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LevelSelectionScreen(),
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
    );
  }
}

class LevelSelectionScreen extends StatelessWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final levels = buildLevels();
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: levels.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final config = levels[index];
            return FilledButton.tonal(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameplayScreen(config: config),
                  ),
                );
              },
              child: Text('${config.level}'),
            );
          },
        ),
      ),
    );
  }
}

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({required this.config, super.key});

  final LevelConfig config;

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
    final random = Random(widget.config.level);
    final cellCount = widget.config.gridSize * widget.config.gridSize;
    final shuffled = List<int>.generate(cellCount, (index) => index)
      ..shuffle(random);

    setState(() {
      _targets = shuffled.take(widget.config.objectCount).toSet();
      _correct.clear();
      _wrong.clear();
      _phase = GamePhase.memorize;
      _mistakes = 0;
    });

    _timer?.cancel();
    _timer = Timer(widget.config.showTime, () {
      if (mounted) {
        setState(() => _phase = GamePhase.recall);
      }
    });
  }

  void _handleCellTap(int index) {
    if (_phase != GamePhase.recall ||
        _correct.contains(index) ||
        _wrong.contains(index)) {
      return;
    }

    if (_targets.contains(index)) {
      setState(() {
        _correct.add(index);
        if (_correct.length == _targets.length) {
          _phase = GamePhase.won;
        }
      });
      if (_phase == GamePhase.won) {
        _showResultDialog(won: true);
      }
      return;
    }

    setState(() {
      _wrong.add(index);
      _mistakes += 1;
      if (_mistakes >= maxHearts) {
        _phase = GamePhase.lost;
      }
    });

    if (_phase == GamePhase.lost) {
      _showResultDialog(won: false);
    }
  }

  int get _stars => max(1, maxHearts - _mistakes);

  void _showResultDialog({required bool won}) {
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(won ? 'Level complete' : 'Try again'),
            content: won
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Icon(
                        index < _stars ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFD166),
                        size: 36,
                      );
                    }),
                  )
                : const Text('All hearts are gone. Replay this board.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Levels'),
              ),
              FilledButton.icon(
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
    });
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
  final ValueChanged<int> onTap;

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

