import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/domain/repositories/settings_repository.dart';

class SettingsRepository implements ISettingsRepository {
  static const _themeModeKey = 'theme_mode_pref';
  static const _primaryColorKey = 'theme_primary_color';
  static const _presetKey = 'preset_profile_key';

  @override
  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }

  @override
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  @override
  Future<void> setPrimaryColorValue(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, colorValue);
  }

  @override
  Future<int> getPrimaryColorValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_primaryColorKey) ?? 0xFF2196F3;
  }

  @override
  Future<void> setSelectedPreset(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_presetKey, key);
  }

  @override
  Future<String?> getSelectedPreset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_presetKey);
  }
}
