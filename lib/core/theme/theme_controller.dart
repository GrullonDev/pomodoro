import 'package:flutter/material.dart';

import 'package:pomodoro/core/di/service_locator.dart';

/// Singleton con ValueNotifier para reaccionar a cambios de tema.
/// Se inicializa en main antes de runApp, y se actualiza desde Settings.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system); // default system

  Future<void> load() async {
    final modeStr = await ServiceLocator.I.settingsRepository.getThemeMode();
    themeMode.value = _parseStr(modeStr);
  }

  Future<void> setMode(ThemeMode mode) async {
    themeMode.value = mode;
    await ServiceLocator.I.settingsRepository.setThemeMode(mode.name);
  }

  ThemeMode _parseStr(String str) {
    if (str == 'light') return ThemeMode.light;
    if (str == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }
}
