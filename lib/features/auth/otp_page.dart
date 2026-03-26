import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../../core/services/auth_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';

class OtpPage extends StatefulWidget {
  final AuthRoutingDecision decision;

  const OtpPage({
    super.key,
    required this.decision,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> with CodeAutoFill {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void dispose() {
    cancel();
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  bool get isValidOtp => _otpController.text.length == 6;

  @override
  void initState() {
    super.initState();
    listenForCode();
    _startCountdown();
  }

  @override
  void codeUpdated() {
    final code = this.code;
    if (code == null || code.isEmpty) return;
    final otp = RegExp(r'\d{4,6}').firstMatch(code)?.group(0);
    if (otp == null) return;
    _otpController.text = otp;
    setState(() {});
    if (otp.length >= 4) {
      _verifyOtp();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 0) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: SafeArea(
          child: Center(
            child: _glassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Code sent to',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.decision.identifier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _otpInput(),

                    const SizedBox(height: 30),

                    _glassButton(
                      text: _loading ? 'Verifying…' : 'Verify OTP',
                      enabled: isValidOtp && !_loading,
                      onTap: _onVerify,
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: (_loading || _secondsLeft > 0) ? null : _resendOtp,
                      child: Text(
                        _secondsLeft > 0 ? 'Resend OTP in ${_secondsLeft}s' : 'Resend OTP',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
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

  // ---------------- UI COMPONENTS ----------------

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _otpInput() {
    return TextField(
      controller: _otpController,
      autofocus: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        letterSpacing: 6,
        fontWeight: FontWeight.bold,
      ),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.4),
          letterSpacing: 6,
        ),
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
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: enabled
              ? Colors.white.withOpacity(0.18)
              : Colors.white.withOpacity(0.08),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
          ),
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

  void _onVerify() {
    if (!isValidOtp || _loading) {
      _snack('Please enter a valid OTP');
      return;
    }
    _verifyOtp();
  }

  Future<void> _verifyOtp() async {
    if (_loading || !isValidOtp) return;
    try {
      setState(() => _loading = true);
      await AnalyticsService.logEvent('otp_verified', params: {
        'method': widget.decision.useMobileOtp ? 'mobile' : 'email',
      });
      await AuthApiService.completeOtpAuth(
        decision: widget.decision,
        otp: _otpController.text.trim(),
      );
      await AnalyticsService.logEvent('login_success', params: {
        'is_registered': widget.decision.isRegistered,
      });
      if (!widget.decision.isRegistered) {
        await AnalyticsService.logEvent('auto_register_success');
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (_) => false);
    } catch (e) {
      _snack('Invalid OTP: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      setState(() => _loading = true);
      await AuthApiService.sendLoginOtp(
        isIndia: widget.decision.useMobileOtp,
        identifier: widget.decision.identifier,
      );
      _snack('OTP sent again');
      await AnalyticsService.logEvent('otp_sent', params: {
        'method': widget.decision.useMobileOtp ? 'mobile' : 'email',
      });
      _startCountdown();
    } catch (e) {
      _snack('Could not resend OTP: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
