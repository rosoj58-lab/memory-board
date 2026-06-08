import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import 'level_selection_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.progressRepository,
    super.key,
  });

  final ProgressRepository progressRepository;

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
                      builder: (_) => LevelSelectionScreen(
                        progressRepository: progressRepository,
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
    );
  }
}

