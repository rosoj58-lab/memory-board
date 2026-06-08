import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../ui/main_menu_screen.dart';

class MemoryBoardApp extends StatelessWidget {
  const MemoryBoardApp({
    required this.progressRepository,
    super.key,
  });

  final ProgressRepository progressRepository;

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
      home: MainMenuScreen(progressRepository: progressRepository),
    );
  }
}

