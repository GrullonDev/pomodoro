import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/material.dart';

import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/features/auth/validator/email_validator.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  final String? initialEmail;

  const SignUpScreen({
    super.key,
    required this.onSuccess,
    this.initialEmail,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null) _email.text = widget.initialEmail!;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.registerWithEmail(
        _email.text.trim(),
        _password.text,
        name: _name.text.trim(),
      );
      widget.onSuccess();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'credential-already-in-use':
        return 'Esta cuenta ya existe con un método diferente.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return code.replaceAll('FirebaseAuthException: ', '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor =
        isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor =
        isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);
    final cardBg = isDark
        ? const Color(0xFF13131F).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor =
        isDark ? const Color(0xFF2E2E4A) : const Color(0xFFE0E0F0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Close ─────────────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: subColor),
                      onPressed: () => Navigator.of(context).maybePop(),
                      tooltip: 'Volver',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Brand ─────────────────────────────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.person_add_outlined,
                      size: 32,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Crear cuenta',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu progreso quedará guardado de forma segura.',
                    style:
                        TextStyle(color: subColor, fontSize: 14, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ── Card ──────────────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Name
                              TextFormField(
                                controller: _name,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.person_outline,
                                      size: 18, color: subColor),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'El nombre es requerido'
                                        : null,
                              ),
                              const SizedBox(height: 12),

                              // Email
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Correo',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      size: 18, color: subColor),
                                ),
                                validator: EmailValidator.validate,
                              ),
                              const SizedBox(height: 12),

                              // Password
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Contraseña',
                                  prefixIcon: Icon(Icons.lock_outline,
                                      size: 18, color: subColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: subColor,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                validator: (v) => (v == null || v.length < 6)
                                    ? 'Mínimo 6 caracteres'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              // Confirm password
                              TextFormField(
                                controller: _confirm,
                                obscureText: _obscureConfirm,
                                style: TextStyle(color: textColor),
                                decoration: InputDecoration(
                                  labelText: 'Confirmar contraseña',
                                  prefixIcon: Icon(Icons.lock_outline,
                                      size: 18, color: subColor),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: subColor,
                                    ),
                                    onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) => v != _password.text
                                    ? 'Las contraseñas no coinciden'
                                    : null,
                              ),
                              const SizedBox(height: 24),

                              // Error
                              if (_error != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            Colors.red.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Submit
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Crear cuenta'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Already have account ──────────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      '¿Ya tienes cuenta? Iniciar sesión',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
