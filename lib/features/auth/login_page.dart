import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/services/auth_api_service.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import 'otp_page.dart';

class LoginPage extends StatefulWidget {
  final String? mobile;

  const LoginPage({super.key, this.mobile});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isIndia = true;

  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _loading = false;

  bool get isValid {
    if (isIndia) {
      return mobileController.text.trim().length == 10;
    } else {
      return emailController.text.trim().contains('@') &&
          passwordController.text.trim().length >= 6;
    }
  }

  @override
  void dispose() {
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
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

  // ✅ GOOGLE SIGN-IN (WEB + MOBILE)
  Future<void> _signInWithGoogle() async {
    try {
      await _setLoading(true);

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize();
        final googleUser = await googleSignIn.authenticate();
        final clientAuth = await googleUser.authorizationClient
            .authorizeScopes(['email', 'profile', 'openid']);
        final credential = GoogleAuthProvider.credential(
          idToken: googleUser.authentication.idToken,
          accessToken: clientAuth.accessToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // ✅ Optional: sync/login with Bloomory backend using Firebase ID token
     final user = FirebaseAuth.instance.currentUser;
if (user != null) {
  final String? idToken = await user.getIdToken();

if (idToken == null || idToken.isEmpty) {
  _snack("Google Sign-In failed: missing idToken.");
  return;
}

try {
  await AuthApiService.loginWithGoogleIdToken(idToken);
} catch (_) {
  // ignore backend sync errors for now
}

}


      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _snack('Google login failed: ${e.message ?? e.code}');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _snack('Google sign-in canceled');
      } else {
        _snack('Google sign-in failed: $e');
      }
    } catch (e) {
      _snack('Google login failed: $e');
    } finally {
      await _setLoading(false);
    }
  }

  // ✅ EMAIL/PASSWORD (GLOBAL MODE)
  Future<void> _signInWithEmailPassword() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    try {
      await _setLoading(true);

      // ✅ Manual email/password login goes to Bloomory Node/Mongo API
      await AuthApiService.loginWithEmail(email, pass);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (_) => false,
      );
    } catch (e) {
      _snack('Login failed: $e');
    } finally {
      await _setLoading(false);
    }
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
                      isIndia
                          ? 'Login using your mobile number'
                          : 'Login using email & password',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 24),
                    _countryToggle(),
                    const SizedBox(height: 24),

                    if (isIndia)
                      _inputField(
                        controller: mobileController,
                        hint: '10-digit mobile number',
                        keyboard: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                      ),

                    if (!isIndia) ...[
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
                    ],

                    const SizedBox(height: 30),

                    _glassButton(
                      text: _loading ? 'Please wait…' : 'Continue',
                      enabled: isValid && !_loading,
                      onTap: _onContinue,
                    ),

                    const SizedBox(height: 20),
                    _divider(),
                    const SizedBox(height: 20),

                    _googleButton(),

                    const SizedBox(height: 12),
                    _registerLink(),
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

  Widget _googleButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _loading ? null : _signInWithGoogle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icons/google.png', height: 20, width: 20),
                const SizedBox(width: 12),
                Text(
                  _loading ? 'Signing in…' : 'Continue with Google',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.6))),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
      ],
    );
  }

  Widget _registerLink() {
    return Center(
      child: TextButton(
        onPressed: _loading
            ? null
            : () => Navigator.pushNamed(context, AppRoutes.register),
        child: const Text(
          "Don't have an account? Register",
          style: TextStyle(
            color: Colors.white,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  // ---------------- LOGIC ----------------

  void _onContinue() {
    if (_loading) return;

    if (isIndia) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpPage(mobile: mobileController.text.trim()),
        ),
      );
    } else {
      if (!isValid) return;
      _signInWithEmailPassword();
    }
  }
}
