/// Abstraction for user settings (theme, preset selection, colors).
abstract class ISettingsRepository {
  Future<void> setThemeMode(String mode);
  Future<String> getThemeMode();
  Future<void> setPrimaryColorValue(int colorValue);
  Future<int> getPrimaryColorValue();
  Future<void> setSelectedPreset(String key);
  Future<String?> getSelectedPreset();
}
