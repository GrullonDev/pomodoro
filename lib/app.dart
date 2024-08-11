import 'package:flutter/material.dart';

import 'package:pomodoro/landing.dart';

// Import the package required to fix window size window management

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (BuildContext context) {
          final mediaQueryData = MediaQuery.of(context);
          const screenWidth = 250.0;
          const screenHeight = 400.0;
          return MediaQuery(
            data: mediaQueryData.copyWith(
              size: const Size(screenWidth, screenHeight),
              devicePixelRatio: mediaQueryData.devicePixelRatio,
            ),
            child: SizedBox(
              width: screenWidth,
              height: screenHeight,
              child: LandingPage(),
            ),
          );
        },
      ),
    );
  }
}
