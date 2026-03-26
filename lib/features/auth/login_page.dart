import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../services/analytics_service.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _identifierController = TextEditingController();
  AuthRoutingDecision? _decision;
  Timer? _detectDebounce;

  bool _loading = false;

  bool get isValid => _identifierController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _detectDebounce?.cancel();
    _identifierController.dispose();
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

  Future<void> _detectAndSendOtp() async {
    final identifier = _identifierController.text.trim();
    try {
      await _setLoading(true);
      await AnalyticsService.logEvent('login_attempt');
      final decision = await AuthApiService.detectUser(identifier);
      setState(() => _decision = decision);
      await AuthApiService.sendLoginOtp(
        isIndia: decision.useMobileOtp,
        identifier: decision.identifier,
      );
      await AnalyticsService.logEvent('otp_sent', params: {
        'method': decision.useMobileOtp ? 'mobile' : 'email',
        'country': decision.country,
      });
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(
            decision: decision,
          ),
        ),
      );
    } catch (e) {
      // Fallback to email OTP if backend detection fails.
      try {
        final fallback = AuthRoutingDecision(
          country: 'UNKNOWN',
          loginType: 'email',
          isRegistered: true,
          identifier: identifier,
        );
        setState(() => _decision = fallback);
        await AuthApiService.sendLoginOtp(
          isIndia: false,
          identifier: identifier,
        );
        await AnalyticsService.logEvent('otp_sent', params: {
          'method': 'email',
          'country': 'UNKNOWN',
          'fallback': true,
        });
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpPage(decision: fallback)),
        );
      } catch (fallbackErr) {
        _snack('OTP send failed: $fallbackErr');
      }
    } finally {
      await _setLoading(false);
    }
  }

  void _onIdentifierChanged(String value) {
    setState(() {});
    _detectDebounce?.cancel();
    final input = value.trim();
    if (input.isEmpty) {
      setState(() => _decision = null);
      return;
    }
    _detectDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final decision = await AuthApiService.detectUser(input);
        if (!mounted) return;
        // Respect backend as source of truth for login method.
        setState(() => _decision = decision);
      } catch (_) {
        // Do not block UX on detect errors; fallback happens on submit.
      }
    });
  }

  // ---------------- UI ----------------

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
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _decision == null
                          ? 'Enter mobile number or email'
                          : _decision!.useMobileOtp
                              ? 'Login using Mobile OTP'
                              : 'Login using Email OTP',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    _inputField(
                      controller: _identifierController,
                      hint: _decision == null
                          ? 'Mobile number or email'
                          : _decision!.useMobileOtp
                              ? '10-digit mobile number'
                              : 'Email address',
                      keyboard: _decision == null
                          ? TextInputType.text
                          : (_decision!.useMobileOtp
                              ? TextInputType.phone
                              : TextInputType.emailAddress),
                      onChanged: _onIdentifierChanged,
                    ),

                    const SizedBox(height: 30),

                    _glassButton(
                      text: _loading ? 'Please wait…' : 'Send OTP',
                      enabled: isValid && !_loading,
                      onTap: _onContinue,
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

  // ---------------- LOGIC ----------------

  void _onContinue() {
    if (_loading || !isValid) return;
    _detectAndSendOtp();
  }
}
