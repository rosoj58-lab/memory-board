import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../data/settings_repository.dart';
import 'route_observer.dart';
import '../ui/app_chrome.dart';
import '../ui/main_menu_screen.dart';

class MemoryBoardApp extends StatelessWidget {
  const MemoryBoardApp({
    required this.progressRepository,
    required this.settingsRepository,
    super.key,
  });

  final ProgressRepository progressRepository;
  final SettingsRepository settingsRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Board',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [memoryBoardRouteObserver],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.background,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          centerTitle: true,
          toolbarHeight: 64,
        ),
        useMaterial3: true,
      ),
      home: MainMenuScreen(
        progressRepository: progressRepository,
        settingsRepository: settingsRepository,
      ),
    );
  }
}
