import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({required this.hapticsEnabled});

  factory AppSettings.initial() {
    return const AppSettings(hapticsEnabled: true);
  }

  final bool hapticsEnabled;

  AppSettings copyWith({bool? hapticsEnabled}) {
    return AppSettings(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<AppSettings> setHapticsEnabled(bool enabled);
}

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._preferences);

  static const _hapticsEnabledKey = 'haptics_enabled';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      hapticsEnabled: _preferences.getBool(_hapticsEnabledKey) ?? true,
    );
  }

  @override
  Future<AppSettings> setHapticsEnabled(bool enabled) async {
    await _preferences.setBool(_hapticsEnabledKey, enabled);
    return AppSettings(hapticsEnabled: enabled);
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings? initialSettings])
      : _settings = initialSettings ?? AppSettings.initial();

  AppSettings _settings;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<AppSettings> setHapticsEnabled(bool enabled) async {
    _settings = _settings.copyWith(hapticsEnabled: enabled);
    return _settings;
  }
}
