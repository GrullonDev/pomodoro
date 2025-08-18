import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pomodoro/core/di/injection.dart' show sl;
import 'package:pomodoro/features/auth/auth_repository.dart';
import 'package:pomodoro/features/auth/screens/sign_up_screen.dart';
import 'package:pomodoro/features/auth/validator/email_validator.dart';
import 'package:pomodoro/utils/app.dart' show AnimatedGradientShell;
import 'package:pomodoro/utils/home_page.dart' show HomePage;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Check if email exists in Firebase (best-effort). If no Firebase, fall back to AuthService sign in.
      final email = _email.text.trim();
      // If Firebase available, try to fetch sign-in methods for email to check existence via repository.
      final repo = sl<AuthRepository>();
      bool emailExists = true;
      try {
        final methodsFetched = await repo.fetchSignInMethodsForEmail(email);
        emailExists = methodsFetched.isNotEmpty;
      } catch (e) {
        emailExists = true;
      }

      if (!emailExists) {
        // Show dialog suggesting registration
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cuenta no encontrada'),
            content: const Text(
                'No existe una cuenta con ese correo. ¿Deseas registrarte?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  // Navigate to sign up screen with pre-filled email
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => SignUpScreen(
                          onSuccess: () {
                            if (!mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AnimatedGradientShell(
                                  child: HomePage(),
                                ),
                              ),
                            );
                          },
                          initialEmail: email)));
                },
                child: const Text('Registrarse'),
              ),
            ],
          ),
        );
        return;
      }

      await repo.signInWithEmail(email, _password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AnimatedGradientShell(child: HomePage()),
        ),
      );
    } catch (e) {
      var msg = e.toString();
      if (e is PlatformException && e.message != null) msg = e.message!;
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Registration handled by dedicated SignUpScreen.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Card(
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Welcome',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      validator: (v) => EmailValidator.validate(v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'La contraseña debe tener al menos 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loading
                            ? null
                            : () {
                                final email = _email.text.trim();
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => SignUpScreen(
                                        onSuccess: () {},
                                        initialEmail: email)));
                              },
                        child: const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        // Load policy asset and show it in a scrollable dialog
                        String policyText;
                        try {
                          policyText = await rootBundle
                              .loadString('assets/terms_privacy.md');
                        } catch (e) {
                          policyText =
                              'Policy file not found. Please check assets.';
                        }

                        if (!mounted) return;
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Terms & Privacy'),
                            content: SingleChildScrollView(
                              child: Text(policyText),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'))
                            ],
                          ),
                        );
                      },
                      child: const Text('Terms & Privacy',
                          style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
