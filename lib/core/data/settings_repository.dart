import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/core/domain/repositories/settings_repository.dart';

class SettingsRepository implements ISettingsRepository {
  static const _themeDarkKey = 'theme_dark_enabled';
  static const _primaryColorKey = 'theme_primary_color';
  static const _presetKey = 'preset_profile_key';

  @override
  Future<void> setThemeDarkEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeDarkKey, enabled);
  }

  @override
  Future<bool> isThemeDarkEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeDarkKey) ?? false;
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
