import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/services/user_api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    print("👤 PROFILE SCREEN LOADED");
    AnalyticsService.logEvent('profile_started');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    try {
      setState(() => _saving = true);
      print("Sending name: $name");
      print("🚀 Sending payload: ${{
        "name": name,
        "profileCompleted": true,
      }}");
      print("🚀 Token: ${await AuthService.getToken()}");
      final response = await UserApiService.updateMe({
        "name": name,
        "profileCompleted": true,
      });
      final updatedUser = response["user"] as Map<String, dynamic>? ?? <String, dynamic>{};
      print("✅ Updated user: $updatedUser");
      await AuthService.setUser(updatedUser);
      await AuthService.resetOfferPopupSeen();
      final savedUser = await AuthService.getUser();
      print("🔥 FINAL SAVED USER: $savedUser");
      print("USER AFTER SAVE: ${await AuthService.getUser()}");
      final user = await AuthService.getUser() ?? <String, dynamic>{};
      print("PROFILE COMPLETED: ${user["profileCompleted"]}");
      await AnalyticsService.logEvent('profile_completed');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
          child: SafeArea(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete your profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'One quick step before entering Bloomory.',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white.withOpacity(0.18),
                              border: Border.all(color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Text(
                              _saving ? 'Saving…' : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
