import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:pomodoro/core/auth/auth_service.dart';
import 'package:pomodoro/features/auth/screens/sign_up_screen.dart';
import 'package:pomodoro/features/auth/validator/email_validator.dart';

/// Shown when the user explicitly wants to save / sync their progress.
/// Never forced on first launch — the app uses anonymous (guest) mode by default.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _showEmailForm = false;
  bool _obscurePassword = true;
  String? _error;

  late final AnimationController _formAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _formHeight =
      CurvedAnimation(parent: _formAnim, curve: Curves.easeOut);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _formAnim.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Auth actions
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _withLoading(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (e) {
      var msg = e.toString();
      if (e is PlatformException && e.message != null) msg = e.message!;
      setState(() => _error = _friendlyError(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    await _withLoading(() =>
        AuthService.instance.signInWithEmail(_email.text.trim(), _password.text));
  }

  Future<void> _signInWithGoogle() async {
    await _withLoading(AuthService.instance.signInWithGoogle);
  }

  Future<void> _signInWithApple() async {
    await _withLoading(AuthService.instance.signInWithApple);
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Inicia sesión.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'credential-already-in-use':
        return 'Esta cuenta ya está vinculada a otro usuario.';
      case 'provider-already-linked':
        return 'Ya tienes este método de inicio de sesión vinculado.';
      default:
        if (code.contains('cancelled') || code.contains('canceled')) {
          return 'Inicio de sesión cancelado.';
        }
        return code
            .replaceAll('Exception: ', '')
            .replaceAll('FirebaseAuthException: ', '');
    }
  }

  void _toggleEmailForm() {
    setState(() => _showEmailForm = !_showEmailForm);
    if (_showEmailForm) {
      _formAnim.forward();
    } else {
      _formAnim.reverse();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final textColor = isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E);
    final subColor = isDark ? const Color(0xFF8A8AB0) : const Color(0xFF6B6B8A);
    final cardBg = isDark
        ? const Color(0xFF13131F).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? const Color(0xFF2E2E4A)
        : const Color(0xFFE0E0F0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Back / close button ───────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: subColor),
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
                      Icons.timer_outlined,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Guarda tu progreso',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sincroniza sesiones y tareas en todos tus dispositivos.',
                    style: TextStyle(color: subColor, fontSize: 14, height: 1.5),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Google button ─────────────────────────────
                            _SocialButton(
                              onPressed: _loading ? null : _signInWithGoogle,
                              loading: _loading,
                              icon: _GoogleIcon(),
                              label: 'Continuar con Google',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),

                            // ── Apple button (iOS / macOS only) ───────────
                            if (Platform.isIOS || Platform.isMacOS) ...[
                              _SocialButton(
                                onPressed: _loading ? null : _signInWithApple,
                                loading: _loading,
                                icon: Icon(
                                  Icons.apple_rounded,
                                  size: 22,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                label: 'Continuar con Apple',
                                isDark: isDark,
                                isApple: true,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ── Divider ───────────────────────────────────
                            _Divider(color: borderColor, subColor: subColor),
                            const SizedBox(height: 12),

                            // ── Email toggle button ───────────────────────
                            OutlinedButton.icon(
                              onPressed: _toggleEmailForm,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                foregroundColor: textColor,
                              ),
                              icon: Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: subColor,
                              ),
                              label: Text(
                                'Continuar con correo',
                                style: TextStyle(
                                    color: textColor, fontWeight: FontWeight.w500),
                              ),
                            ),

                            // ── Email form (animated) ─────────────────────
                            SizeTransition(
                              sizeFactor: _formHeight,
                              axisAlignment: -1,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 16),
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
                                      validator: (v) =>
                                          (v == null || v.length < 6)
                                              ? 'Mínimo 6 caracteres'
                                              : null,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _loading ? null : _signInWithEmail,
                                        child: _loading
                                            ? const SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white),
                                              )
                                            : const Text('Iniciar sesión'),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => SignUpScreen(
                                                    onSuccess: () {},
                                                    initialEmail:
                                                        _email.text.trim(),
                                                  ),
                                                ),
                                              ),
                                      child: Text(
                                        '¿No tienes cuenta? Crear cuenta',
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ── Error message ─────────────────────────────
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3)),
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
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Continue without account ──────────────────────────────
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Continuar sin cuenta',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: subColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Terms ─────────────────────────────────────────────────
                  TextButton(
                    onPressed: _showTerms,
                    child: Text(
                      'Términos y Privacidad',
                      style: TextStyle(
                          fontSize: 11,
                          color: subColor.withValues(alpha: 0.7)),
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

  Future<void> _showTerms() async {
    String policyText;
    try {
      policyText =
          await rootBundle.loadString('assets/terms_privacy.md');
    } catch (_) {
      policyText = 'Archivo de política no encontrado.';
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Términos y Privacidad'),
        content:
            SingleChildScrollView(child: Text(policyText)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'))
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final Widget icon;
  final String label;
  final bool isDark;
  final bool isApple;

  const _SocialButton({
    required this.onPressed,
    required this.loading,
    required this.icon,
    required this.label,
    required this.isDark,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isApple
        ? (isDark ? Colors.white : Colors.black)
        : (isDark ? const Color(0xFF1E1E30) : Colors.white);
    final textColor = isApple
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? const Color(0xFFEEEEF6) : const Color(0xFF1A1A2E));
    final borderColor =
        isDark ? const Color(0xFF2E2E4A) : const Color(0xFFE0E0F0);

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor.withValues(alpha: 0.7)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A simple Google "G" rendered with the brand's four colors.
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle split into four colored arcs
          CustomPaint(size: const Size(22, 22), painter: _GoogleArcPainter()),
        ],
      ),
    );
  }
}

class _GoogleArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.5;
    final strokeW = size.width * 0.22;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Clockwise from right: blue → green → yellow → red
    arc(const Color(0xFF4285F4), -0.25, 1.55);   // blue (right)
    arc(const Color(0xFF34A853), 1.30, 1.55);    // green (bottom)
    arc(const Color(0xFFFBBC05), 2.85, 0.78);    // yellow (lower-left)
    arc(const Color(0xFFEA4335), 3.63, 0.77);    // red (upper-left)

    // Horizontal white bar forming the right part of the "G"
    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - 0.5,
          center.dy - size.height * 0.14,
          size.width * 0.5,
          size.height * 0.27),
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Divider extends StatelessWidget {
  final Color color;
  final Color subColor;

  const _Divider({required this.color, required this.subColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o usa tu correo',
            style: TextStyle(color: subColor, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: color, thickness: 1)),
      ],
    );
  }
}

