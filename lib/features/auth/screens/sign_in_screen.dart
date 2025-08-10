import 'package:flutter/material.dart';

class SignInScreen extends StatelessWidget {
  final VoidCallback onSuccess;
  const SignInScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    void goSignUp() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SignUpScreen(onSuccess: onSuccess),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Pomodoro', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text('Welcome back',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(height: 24),
              _PrimaryButton(text: 'Continue with Phone', onTap: onSuccess),
              const SizedBox(height: 12),
              _SecondaryButton(text: 'Continue with Google', onTap: onSuccess),
              const SizedBox(height: 12),
              _SecondaryButton(text: 'Continue with Email', onTap: onSuccess),
              const SizedBox(height: 12),
              TextButton(
                onPressed: goSignUp,
                child: const Text("Don't have an account? Sign up",
                    style: TextStyle(color: Colors.black54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  // fallback if imported directly
  final VoidCallback onSuccess;
  const SignUpScreen({super.key, required this.onSuccess});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: TextButton(onPressed: onSuccess, child: const Text('Done'))));
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _PrimaryButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A74E6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SecondaryButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          backgroundColor: const Color(0xFFEFF3F7),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
