import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isIndia = true;
  bool _loading = false;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool get _isValid {
    final nameOk = nameController.text.trim().isNotEmpty;
    final pass = passwordController.text.trim();
    final confirm = confirmController.text.trim();
    final passOk = pass.length >= 6 && pass == confirm;

    if (!nameOk || !passOk) return false;

    if (isIndia) {
      return phoneController.text.trim().length == 10;
    }
    return emailController.text.trim().contains('@');
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _setLoading(bool v) async {
    if (!mounted) return;
    setState(() => _loading = v);
  }

  Future<void> _register() async {
    if (_loading || !_isValid) return;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    try {
      await _setLoading(true);

      await AuthApiService.register(
        name: name,
        phone: isIndia ? phone : null,
        email: isIndia ? null : email,
        password: pass,
      );

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } catch (e) {
      _snack('Registration failed: $e');
    } finally {
      await _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: Center(
            child: _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isIndia
                          ? 'Register using your mobile number'
                          : 'Register using email & password',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    _countryToggle(),
                    const SizedBox(height: 24),

                    _inputField(
                      controller: nameController,
                      hint: 'Full name',
                      keyboard: TextInputType.name,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    if (isIndia)
                      _inputField(
                        controller: phoneController,
                        hint: '10-digit mobile number',
                        keyboard: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                      ),

                    if (!isIndia)
                      _inputField(
                        controller: emailController,
                        hint: 'Email address',
                        keyboard: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                      ),

                    const SizedBox(height: 16),
                    _inputField(
                      controller: passwordController,
                      hint: 'Password (min 6)',
                      obscure: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _inputField(
                      controller: confirmController,
                      hint: 'Confirm password',
                      obscure: true,
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 30),
                    _glassButton(
                      text: _loading ? 'Creating…' : 'Create account',
                      enabled: _isValid && !_loading,
                      onTap: _register,
                    ),

                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _countryToggle() {
    return GestureDetector(
      onTap: () => setState(() => isIndia = !isIndia),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              alignment: isIndia ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
            ),
            Row(
              children: [
                _toggleLabel(text: 'India 🇮🇳', active: isIndia),
                _toggleLabel(text: 'Global 🌍', active: !isIndia),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleLabel({required String text, required bool active}) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _glassButton({
    required String text,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: enabled
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
