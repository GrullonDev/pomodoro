import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  final VoidCallback onSuccess;
  const SignUpScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    void goSignIn() => Navigator.of(context).maybePop();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Sign up', style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const _TextField(hint: 'Name'),
              const SizedBox(height: 12),
              const _TextField(hint: 'Email'),
              const SizedBox(height: 12),
              const _TextField(hint: 'Password', obscure: true),
              const SizedBox(height: 12),
              const _TextField(hint: 'Confirm Password', obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSuccess,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A74E6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sign up',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Or sign up with',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialButton(label: 'Phone', onTap: onSuccess),
                  const SizedBox(width: 16),
                  _SocialButton(label: 'Google', onTap: onSuccess),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: goSignIn,
                child: const Text('Already have an account? Sign in',
                    style: TextStyle(color: Colors.black54)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  const _TextField({required this.hint, this.obscure = false});
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEFF3F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFEFF3F7),
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
