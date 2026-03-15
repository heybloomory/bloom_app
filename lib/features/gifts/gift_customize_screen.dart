import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'gift_data.dart';
import 'gift_image.dart';

class GiftCustomizeScreen extends StatelessWidget {
  final String productId;

  const GiftCustomizeScreen({super.key, required this.productId});

  static GiftCustomizeScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final id = (map['id'] ?? 'pfc_heart').toString();
    return GiftCustomizeScreen(productId: id);
  }

  @override
  Widget build(BuildContext context) {
    final product = GiftData.byId(productId);

    return MainAppShell(
      currentRoute: AppRoutes.gifts,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Customize Gift',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personalization Preview',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFF1B8E68),
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GlassContainer(
                radius: 18,
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: GiftImage(
                    path: product.primaryImage,
                    width: double.infinity,
                    height: 300,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                radius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To  Emily Johnson', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    const Text('From  Aditya', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    const GlassContainer(
                      radius: 16,
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'A keepsake of our love story',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.white54),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('#OurLoveStory  💗', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    const _ToolsRow(
                      tools: [
                        _Tool('Replace', Icons.image),
                        _Tool('Text', Icons.text_fields),
                        _Tool('Crop', Icons.crop),
                        _Tool('Rotate', Icons.rotate_right),
                        _Tool('Filters', Icons.tune),
                        _Tool('Enhance', Icons.auto_awesome),
                        _Tool('Erase', Icons.auto_fix_high),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.giftCheckout,
                        arguments: {'id': product.id},
                      ),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD79A4E).withOpacity(0.90),
                              const Color(0xFFB66A2F).withOpacity(0.90),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolsRow extends StatelessWidget {
  final List<_Tool> tools;
  const _ToolsRow({required this.tools});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tools
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, color: Colors.white70),
                      const SizedBox(height: 6),
                      Text(
                        t.label,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Tool {
  final String label;
  final IconData icon;
  const _Tool(this.label, this.icon);
}
