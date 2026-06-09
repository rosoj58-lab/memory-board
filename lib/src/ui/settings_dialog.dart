import 'package:flutter/material.dart';

import '../data/progress_repository.dart';
import '../data/settings_repository.dart';

Future<bool> showSettingsDialog({
  required BuildContext context,
  required SettingsRepository settingsRepository,
  ProgressRepository? progressRepository,
}) async {
  var settingsFuture = settingsRepository.load();
  var progressReset = false;

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

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
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
                    ),
                    if (progressRepository != null) ...[
                      const Divider(height: 24),
                      ListTile(
                        key: const ValueKey('settings-reset-progress-tile'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restart_alt_rounded),
                        title: const Text('Reset progress'),
                        subtitle:
                            const Text('Clear levels, stars, and tutorial'),
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Reset all progress?'),
                                content: const Text(
                                  'Levels, stars, and tutorial progress will reset.',
                                ),
                                actions: [
                                  TextButton(
                                    key: const ValueKey('reset-cancel-button'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    key: const ValueKey('reset-confirm-button'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Reset'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed != true) {
                            return;
                          }

                          await progressRepository.reset();
                          progressReset = true;
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ],
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

  return progressReset;
}
