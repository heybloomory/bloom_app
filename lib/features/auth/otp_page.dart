import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class OtpPage extends StatefulWidget {
  final String mobile;

  const OtpPage({super.key, required this.mobile});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  bool get isValidOtp => _otpController.text.length == 6;

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
                      widget.mobile,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _otpInput(),

                    const SizedBox(height: 30),

                    _glassButton(
                      text: 'Verify OTP',
                      enabled: isValidOtp,
                      onTap: _onVerify,
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        // TODO: Resend OTP
                      },
                      child: Text(
                        'Resend OTP',
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
    if (isValidOtp) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid OTP'),
        ),
      );
    }
  }
}
