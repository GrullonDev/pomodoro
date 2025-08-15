/// Abstraction for user settings (theme, preset selection, colors).
abstract class ISettingsRepository {
  Future<void> setThemeDarkEnabled(bool enabled);
  Future<bool> isThemeDarkEnabled();
  Future<void> setPrimaryColorValue(int colorValue);
  Future<int> getPrimaryColorValue();
  Future<void> setSelectedPreset(String key);
  Future<String?> getSelectedPreset();
}
