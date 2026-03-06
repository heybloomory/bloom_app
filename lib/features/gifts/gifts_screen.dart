import 'package:flutter/material.dart';

import '../../core/widgets/glass_container.dart';
import '../../layout/main_app_shell.dart';
import '../../routes/app_routes.dart';
import 'gift_data.dart';
import 'gift_models.dart';

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({super.key});

  void _openAddGift(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _AddGiftDialog(),
    );
  }

  void _openCategory(BuildContext context, {
    required String category,
    required String title,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.giftCategory,
      arguments: {
        'category': category,
        'title': title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainAppShell(
      currentRoute: AppRoutes.gifts,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Gifts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openAddGift(context),
                    child: GlassContainer(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: const [
                          Icon(Icons.add, color: Colors.white70, size: 18),
                          SizedBox(width: 6),
                          Text('Add Gift', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.notifications_none, color: Colors.white70),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage('assets/images/profile.jpg'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search
              GlassContainer(
                radius: 22,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Colors.white70),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search gifts for your loved ones...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    Icon(Icons.menu, color: Colors.white70),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Shop by occasions
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shop by Occasions ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 145,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _OccasionCard(
                      label: 'Birthdays',
                      icon: Icons.cake,
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'photo_frame_collages',
                        title: 'Photo Frame Collages',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _OccasionCard(
                      label: 'Anniversaries',
                      icon: Icons.favorite,
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'photo_frame_collages',
                        title: 'Photo Frame Collages',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _OccasionCard(
                      label: 'Baby Moments',
                      icon: Icons.child_care,
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'custom_photo_albums',
                        title: 'Custom Photo Albums',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Dots (simple)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 3 ? Colors.white70 : Colors.white24,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Goa trip section
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Goa Trip, March 10–13, 2025 · 24 Photos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BigGiftCard(
                      title: 'Photo Frame\nCollages',
                      leading: Icons.grid_view,
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'photo_frame_collages',
                        title: 'Photo Frame Collages',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BigGiftCard(
                      title: 'Custom Photo\nAlbums',
                      leading: Icons.favorite,
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'custom_photo_albums',
                        title: 'Custom Photo Albums',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Signature gifts
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Signature Gifts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.chevron_right,
                        color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _MiniGiftCard(
                      title: 'Photo Frame\nCollages',
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'photo_frame_collages',
                        title: 'Photo Frame Collages',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MiniGiftCard(
                      title: 'Custom Photo\nAlbums',
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'custom_photo_albums',
                        title: 'Custom Photo Albums',
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MiniGiftCard(
                      title: 'Engraved\nKeepsakes',
                      assetPath: 'assets/images/sample.jpg',
                      onTap: () => _openCategory(
                        context,
                        category: 'engraved_keepsakes',
                        title: 'Engraved Keepsakes',
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

class _OccasionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final String assetPath;
  final VoidCallback onTap;

  const _OccasionCard({
    required this.label,
    required this.icon,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 210,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  assetPath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BigGiftCard extends StatelessWidget {
  final String title;
  final IconData leading;
  final String assetPath;
  final VoidCallback onTap;

  const _BigGiftCard({
    required this.title,
    required this.leading,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          height: 130,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  assetPath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(leading, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniGiftCard extends StatelessWidget {
  final String title;
  final String assetPath;
  final VoidCallback onTap;

  const _MiniGiftCard({
    required this.title,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        radius: 18,
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 160,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  assetPath,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.photo, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGiftDialog extends StatefulWidget {
  const _AddGiftDialog();

  @override
  State<_AddGiftDialog> createState() => _AddGiftDialogState();
}

class _AddGiftDialogState extends State<_AddGiftDialog> {
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _category = 'photo_frame_collages';
  final List<TextEditingController> _imageCtrls = [TextEditingController()];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    _locationCtrl.dispose();
    for (final c in _imageCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    setState(() => _imageCtrls.add(TextEditingController()));
  }

  void _removeImageField(int index) {
    if (_imageCtrls.length <= 1) return;
    final c = _imageCtrls.removeAt(index);
    c.dispose();
    setState(() {});
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    final discounted = int.tryParse(_discountCtrl.text.trim());

    if (title.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid title and price.')),
      );
      return;
    }

    if (discounted != null && (discounted <= 0 || discounted > price)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Discount price must be less than or equal to price.')),
      );
      return;
    }

    final images = _imageCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final product = GiftProduct(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      category: _category,
      title: title,
      price: price,
      discountedPrice: discounted,
      location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      images: images.isEmpty ? const ['assets/images/sample.jpg'] : images,
      rating: 4.7,
    );

    GiftData.addProduct(product);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gift added (demo).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.9;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxH),
        child: GlassContainer(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Add Gift',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    )
                  ],
                ),
                const SizedBox(height: 10),

                const Text('Category', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: const Color(0xFF1C1230),
                  decoration: _fieldDecoration('Select category'),
                  items: const [
                    DropdownMenuItem(
                      value: 'photo_frame_collages',
                      child: Text('Photo Frame Collages', style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'custom_photo_albums',
                      child: Text('Custom Photo Albums', style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: 'engraved_keepsakes',
                      child: Text('Engraved Keepsakes', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),

                const SizedBox(height: 12),
                const Text('Title', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Gift title'),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Price', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration('e.g. 69'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('After discount (optional)', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _discountCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration('e.g. 55'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text('Location (optional)', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('e.g. Mumbai, IN'),
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Gift Images (multiple)',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addImageField,
                      icon: const Icon(Icons.add, color: Colors.white70, size: 18),
                      label: const Text('Add', style: TextStyle(color: Colors.white70)),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tip: You can paste image URLs (https://...) or leave empty to use a demo image.',
                  style: TextStyle(color: Colors.white54, height: 1.3),
                ),
                const SizedBox(height: 10),
                ...List.generate(_imageCtrls.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _imageCtrls[i],
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDecoration('Image URL #${i + 1}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeImageField(i),
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                        )
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Gift'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
