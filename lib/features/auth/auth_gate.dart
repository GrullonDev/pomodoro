import 'package:flutter/material.dart';

import 'package:pomodoro/features/auth/auth_repository.dart';
import 'package:pomodoro/features/auth/screens/onboarding_screen.dart';
import 'package:pomodoro/features/auth/screens/sign_in_screen.dart';
import 'package:pomodoro/utils/home_page.dart';

/// Simple local / pseudo-auth gate.
/// Rules:
/// - If user marked as loggedIn (local flag) -> go HomePage.
/// - Else show onboarding first; from onboarding user can proceed to sign in / up.
/// - Account types: local-only (guest) or future Google/email. For now just store a flag.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authRepo.userChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user != null) {
          return const HomePage();
        }
        return OnboardingScreen(
          onGetStarted: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SignInScreen(onSuccess: () {}),
              ),
            );
          },
          onSkip: () {}, // remain guest (no auth)
        );
      },
    );
  }
}
