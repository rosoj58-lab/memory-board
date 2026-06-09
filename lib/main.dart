import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app/memory_board_app.dart';
import 'src/data/progress_repository.dart';
import 'src/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final preferences = await SharedPreferences.getInstance();
  runApp(
    MemoryBoardApp(
      progressRepository: PreferencesProgressRepository(preferences),
      settingsRepository: PreferencesSettingsRepository(preferences),
    ),
  );
}
