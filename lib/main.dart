import 'package:flutter/material.dart';

import 'package:pomodoro/utils/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());

  // if (Platform.isMacOS) {
  //   final windowManager = WindowManager.instance;
  //   windowManager.setMinimumSize(const Size(1650, 1600));
  //   windowManager.setMaximumSize(const Size(1650, 1600));
  // }
}
