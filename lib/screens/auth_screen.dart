// ═══════════════════════════════════════════════════════
// screens/auth_screen.dart
// ═══════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _loading = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.graphic_eq, size: 64, color: cs.primary),
              const SizedBox(height: 8),
              Text('dB Neighbors',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: cs.primary)),
              const SizedBox(height: 4),
              Text('מדוד · חבר · תקשר עם שכנייך',
                  style: TextStyle(color: cs.outline)),
              const SizedBox(height: 40),

              if (!_isLogin) ...[
                TextField(controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'שם מלא', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _aptCtrl,
                    decoration: const InputDecoration(
                        labelText: 'מספר דירה', border: OutlineInputBorder())),
                const SizedBox(height: 12),
              ],
              TextField(controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'אימייל', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'סיסמה', border: OutlineInputBorder())),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(_isLogin ? 'כניסה' : 'הרשמה'),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'אין לי חשבון — הרשמה' : 'יש לי חשבון — כניסה'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isLogin) {
        await AuthService().signInWithEmail(
          _emailCtrl.text.trim(), _passCtrl.text);
      } else {
        await AuthService().registerWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          displayName: _nameCtrl.text.trim(),
          apartment: _aptCtrl.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
