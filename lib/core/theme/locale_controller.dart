import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._();
  static final instance = LocaleController._();

  final ValueNotifier<Locale?> locale = ValueNotifier(null);
  static const _key = 'app_locale_code_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      locale.value = Locale(code);
    }
  }

  Future<void> setLocale(Locale? loc) async {
    final prefs = await SharedPreferences.getInstance();
    if (loc == null) {
      await prefs.remove(_key);
      locale.value = null; // system default
    } else {
      await prefs.setString(_key, loc.languageCode);
      locale.value = loc;
    }
  }
}
