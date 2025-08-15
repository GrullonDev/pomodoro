import 'package:flutter/foundation.dart';
import 'package:pomodoro/core/data/session_repository.dart';

/// Singleton con ValueNotifier para reaccionar a cambios de tema.
/// Se inicializa en main antes de runApp, y se actualiza desde Settings.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<bool> isDark =
      ValueNotifier<bool>(true); // default oscuro

  Future<void> load() async {
    isDark.value = await SessionRepository().isThemeDarkEnabled();
  }

  Future<void> setDark(bool value) async {
    isDark.value = value;
    await SessionRepository().setThemeDarkEnabled(value);
  }
}
