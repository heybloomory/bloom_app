import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'gift_data.dart';
import 'gift_image.dart';

class GiftCheckoutScreen extends StatefulWidget {
  final String productId;

  const GiftCheckoutScreen({super.key, required this.productId});

  static GiftCheckoutScreen fromRoute(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map ? args : const {};
    final id = (map['id'] ?? 'pfc_heart').toString();
    return GiftCheckoutScreen(productId: id);
  }

  @override
  State<GiftCheckoutScreen> createState() => _GiftCheckoutScreenState();
}

class _GiftCheckoutScreenState extends State<GiftCheckoutScreen> {
  final _couponController = TextEditingController();
  bool _applied = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = GiftData.byId(widget.productId);
    final shipping = _applied ? 3.80 : 6.95;
    final total = product.price + shipping;

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
                          'Checkout',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review & Confirm Your Order',
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
                    height: 260,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.giftCustomize,
                      arguments: {'id': product.id},
                    );
                  },
                  child: GlassContainer(
                    radius: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, color: Colors.white70, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Gift  >', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To  Emily Johnson', style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 6),
                            Text('From  Aditya', style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 6),
                            Text('A keepsake of our love story', style: TextStyle(color: Colors.white70)),
                            SizedBox(height: 6),
                            Text('#OurLoveStory  💗', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text('Qty 1  >', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _CouponRow(
                      controller: _couponController,
                      applied: _applied,
                      onApply: () => setState(() => _applied = true),
                    ),
                    if (_applied) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF67E3B1), size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Discount code 'SAVE20' applied!",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Spacer(),
                          Text('+ 5.4%', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Shipping Information',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        Text('Edit', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Emily Johnson\n1234 Blossom Ave\nLos Angeles, CA 90015\n+1 555-123-7890',
                      style: TextStyle(color: Colors.white70, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Item Total', style: TextStyle(color: Colors.white70)),
                        Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipping', style: TextStyle(color: Colors.white70)),
                        Text('\$${shipping.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
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
                          'Place Order',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text('🔒  Secure Checkout', style: TextStyle(color: Colors.white70)),
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

class _CouponRow extends StatelessWidget {
  final TextEditingController controller;
  final bool applied;
  final VoidCallback onApply;

  const _CouponRow({
    required this.controller,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Discount coupon code',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: applied ? null : onApply,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.12),
              ),
              child: Text(
                applied ? 'Applied' : 'Apply',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
