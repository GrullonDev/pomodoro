// Home screen that displays the logo and a button to start the session

import 'package:flutter/material.dart';

import 'package:pomodoro/utils/home_page.dart';
import 'package:pomodoro/utils/responsive/responsive.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // The main content of the page
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 1,
                    child: Text(
                      'Bienvenido a Pomodoro',
                      style: TextStyle(
                        fontSize: isMobile ? 28 : 40,
                        color: Colors.white,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: 1,
                    child: SizedBox(
                      width: isMobile ? 120 : 200,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(seconds: 1),
                            pageBuilder:
                                (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: const HomePage(),
                              );
                            },
                          ),
                        ),
                        child: Text(
                          'Iniciar',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: isMobile ? 16 : 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // The footer with the "Made with love in YYC" text
          Container(
            height: isMobile ? 60 : 90,
            alignment: Alignment.center,
            child: Text(
              'Construido por @GrullonDev',
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                color: Colors.white24,
                fontFamily: 'Arial',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
