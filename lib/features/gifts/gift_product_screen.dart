import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'gift_data.dart';
import 'gift_image.dart';

class GiftProductScreen extends StatelessWidget {
  final String productId;

  const GiftProductScreen({super.key, required this.productId});

  static GiftProductScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final id = (map['id'] ?? 'pfc_heart').toString();
    return GiftProductScreen(productId: id);
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
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          product.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Personalization Preview',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
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
                    height: 280,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'To  Emily Johnson',
                          style: TextStyle(color: Colors.white70),
                        ),
                        _PriceTag(price: product.price, discounted: product.discountedPrice),
                      ],
                    ),
                    if (product.location != null && product.location!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Ships from ${product.location}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'From  Aditya',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    GlassContainer(
                      radius: 16,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: const [
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
                    const Text(
                      '#OurLoveStory  💗',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _PillButton(
                            text: 'Customize Again',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.giftCustomize,
                                arguments: {'id': product.id},
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FilledPillButton(
                            text: 'Add to Cart',
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.giftCheckout,
                                arguments: {'id': product.id},
                              );
                            },
                          ),
                        ),
                      ],
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

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 26,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final int price;
  final int? discounted;
  const _PriceTag({required this.price, required this.discounted});

  @override
  Widget build(BuildContext context) {
    if (discounted == null || discounted! >= price) {
      return Text(
        '\$$price',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '\$$price',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 16,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '\$$discounted',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FilledPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FilledPillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFD79A4E).withOpacity(0.85),
              const Color(0xFFB66A2F).withOpacity(0.85),
            ],
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
