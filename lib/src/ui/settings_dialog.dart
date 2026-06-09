import 'package:flutter/material.dart';

import '../data/settings_repository.dart';

Future<void> showSettingsDialog({
  required BuildContext context,
  required SettingsRepository settingsRepository,
}) async {
  var settingsFuture = settingsRepository.load();

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Settings'),
            content: FutureBuilder<AppSettings>(
              future: settingsFuture,
              builder: (context, snapshot) {
                final settings = snapshot.data;
                if (settings == null) {
                  return const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                return SwitchListTile(
                  key: const ValueKey('haptics-toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration'),
                  value: settings.hapticsEnabled,
                  onChanged: (enabled) {
                    setState(() {
                      settingsFuture =
                          settingsRepository.setHapticsEnabled(enabled);
                    });
                  },
                );
              },
            ),
            actions: [
              FilledButton(
                key: const ValueKey('settings-done-button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    },
  );
}
